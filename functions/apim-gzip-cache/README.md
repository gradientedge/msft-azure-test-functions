# APIM gzip cache truncation reproducer

Reproduces the issue where Azure API Management (APIM) with external Redis cache truncates gzip-compressed responses on cache replay.

## Issue summary

When a backend returns a fully buffered gzip response with valid `Content-Length`, APIM:
1. **Cache MISS**: delivers the full response correctly
2. **Cache HIT**: delivers a truncated gzip payload (~1.8-1.9 MB decompressed regardless of original size)

Non-gzip responses are unaffected.

| Scenario  | gzip | cache | Content-Length      |
|-----------|------|-------|---------------------|
| Non-gzip  | no   | any   | present             |
| gzip MISS | yes  | no    | missing             |
| gzip HIT  | yes  | yes   | missing + truncated |

## Endpoints

| Path                          | Compression | Description |
|-------------------------------|-------------|-------------|
| `/api/payload/{size}`         | gzip (if `Accept-Encoding: gzip` and payload ≥ 1 MB) | Main test endpoint |
| `/api/payload-no-gzip/{size}` | none        | Control endpoint — identical payloads, no compression |

### Size parameter

| Value    | Approximate uncompressed size |
|----------|-------------------------------|
| small    | ~10 KB                        |
| medium   | ~500 KB                       |
| large    | ~2 MB                         |
| xlarge   | ~5 MB                         |
| xxlarge  | ~21 MB                        |

### Response headers

- `Cache-Control: public, max-age=300` — enables APIM caching
- `Content-Encoding: gzip` — when compression is applied
- `Content-Length` — accurate byte count (compressed or uncompressed)
- `Vary: Accept-Encoding` — for correct cache keying
- `X-Payload-Size` — requested size parameter
- `X-Payload-Uncompressed-Size` — original JSON byte count
- `X-Payload-Compressed-Size` — compressed byte count
- `X-Payload-Compressed` — `true`/`false`
- `X-Cache-Bypass` — `true` when cache bypass was triggered
- `X-Response-Timestamp` — ISO 8601 timestamp set by the function when the response was generated

### Detecting cache HIT vs MISS

`X-Response-Timestamp` is the reliable way to tell whether a response came from cache:

- **Cache MISS**: backend was called, timestamp is close to current time
- **Cache HIT**: APIM replays the cached response byte-for-byte; timestamp stays frozen at the time the item was first cached
- **Cache BYPASS** (`Cache-Control: no-cache`): backend is always called, fresh timestamp

If two requests to the same URL return the same `X-Response-Timestamp`, the second one was a cache HIT. If the timestamp is stale (older than a few seconds), it is definitely served from cache.

```bash
# First request — note the timestamp
curl -si -H "Accept-Encoding: gzip" https://apim-gzip-test.azure-api.net/gzip-test/payload/large | grep -i x-response-timestamp

# Second request — same timestamp = HIT, different = MISS
curl -si -H "Accept-Encoding: gzip" https://apim-gzip-test.azure-api.net/gzip-test/payload/large | grep -i x-response-timestamp
```

Send `Cache-Control: no-cache` request header to bypass APIM cache (matches the production APIM inbound policy).

Cache key variation in this experiment:

- Path (for example `/payload/large` vs `/payload/xlarge`)
- Header: `Accept-Encoding`
- Query parameter: `id`

Use query parameter `id` to create separate cache buckets for the same endpoint:

```bash
curl -s -D- -H "Accept-Encoding: gzip" "https://apim-gzip-test.azure-api.net/gzip-test/payload/large?id=a" -o /dev/null
curl -s -D- -H "Accept-Encoding: gzip" "https://apim-gzip-test.azure-api.net/gzip-test/payload/large?id=b" -o /dev/null
```

If you want deterministic cache behavior with query strings, always use `id`.

## Prerequisites

- Azure CLI (`az`) logged in with an active subscription
- `jq` installed
- Azure Functions Core Tools (`func`)
- Node.js 22+

## Infrastructure setup

All Azure resources (Function App, APIM, Redis, Storage) are provisioned automatically via scripts. The default setup creates a dedicated test resource group, but you can also point the scripts at an existing APIM instance if you already have one in your subscription.

```bash
# Provision everything (takes ~15-30 min, mostly Redis + APIM)
./infra-up.sh

# Deploy the function code
FUNCTION_NAME=func-apim-gzip-test RESOURCE_GROUP_NAME=rg-apim-gzip-test ./deploy.sh

# Tear down when done (deletes entire resource group)
./infra-down.sh
```

Override defaults via environment variables:

| Variable              | Default                  |
|-----------------------|--------------------------|
| `RESOURCE_GROUP`      | `rg-apim-gzip-test`      |
| `LOCATION`            | `westeurope`             |
| `FUNCTION_NAME`       | `func-apim-gzip-test`    |
| `REDIS_NAME`          | `redis-apim-gzip-test`   |
| `REDIS_SKU`           | `Balanced_B0`            |
| `REDIS_CAPACITY`      | `2`                      |
| `APIM_NAME`           | `functionapimtest`       |
| `APIM_RESOURCE_GROUP` | `playground-kamil`       |

`infra-up.sh` now provisions Redis Enterprise `Balanced_B0` to match the retail setup more closely. By default it reuses the shared `functionapimtest` APIM in `playground-kamil` so you avoid creating another gateway. If you want an isolated APIM, override `APIM_NAME` and `APIM_RESOURCE_GROUP` before running the script.

The `infra-up.sh` script also applies the APIM cache policy automatically, so no manual portal steps are needed.

## APIM cache policy

The policy is applied automatically by `infra-up.sh`. It matches the production policy from `retail-platform-global-services`. For reference:

### Inbound policy (cache-lookup)

```xml
<set-variable name="cacheControlHeader" value="@(context.Request.Headers.GetValueOrDefault("Cache-Control", "").ToLower())" />
<choose>
    <when condition="@(!context.Request.Url.Path.Contains("/health"))">
        <choose>
            <!-- When Cache-Control is not set to no-cache, perform a cache lookup -->
            <when condition="@(!((string)context.Variables["cacheControlHeader"]).Contains("no-cache"))">
                <!-- Attempt to retrieve cached response -->
                <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" must-revalidate="false" downstream-caching-type="public" caching-type="external">
                    <vary-by-header>Accept-Encoding</vary-by-header>
                    <vary-by-query-parameter>id</vary-by-query-parameter>
                </cache-lookup>
            </when>
        </choose>
    </when>
</choose>
```

### Outbound policy (cache-store)

```xml
<choose>
    <when condition="@(!context.Request.Url.Path.Contains("/health"))">
        <choose>
            <!-- When status code is 2xx or 404 and Cache-Control is not set to no-store, store the response in cache -->
            <when condition="@(((context.Response.StatusCode >= 200 && context.Response.StatusCode < 300) || context.Response.StatusCode == 404) && !((string)context.Variables["cacheControlHeader"]).Contains("no-store"))">
                <choose>
                    <!-- Skip storing in cache if response body is large (> 2MB) -->
                    <when condition="@{ var contentLength = context.Response.Headers.GetValueOrDefault("Content-Length", "0"); int length; return !int.TryParse(contentLength, out length) || length <= 2000000; }">
                        <!-- Attempt to store the response in cache -->
                        <cache-store duration="@{
                            var header = context.Response.Headers.GetValueOrDefault("Cache-Control","");
                            var maxAge = Regex.Match(header, "max-age=(?<maxAge>\\d+)").Groups["maxAge"]?.Value;
                            return (!string.IsNullOrEmpty(maxAge))?int.Parse(maxAge):300; }" cache-response="true" />
                    </when>
                </choose>
            </when>
        </choose>
    </when>
</choose>
```

> **Note on the 2 MB threshold**: The outbound policy skips caching when `Content-Length > 2MB`. Since gzip-compressed payloads have a *smaller* Content-Length (e.g., 21 MB uncompressed → ~1.18 MB compressed), they pass this check and get cached — then truncated on cache replay. This is a key factor in the bug.

## Local testing

> **Note**: Local testing verifies that compression, `Content-Length`, `Cache-Control` headers, and cache bypass logic work correctly. However, **the truncation bug cannot be reproduced locally** — it only occurs when responses pass through APIM with an external Redis cache. Use local testing for sanity checks, then test against APIM to reproduce the issue.

```bash
cd functions/apim-gzip-cache
npm ci
npm run build
func start
```

```bash
# gzip response — large payload (above 1MB threshold)
curl -s -D- -H "Accept-Encoding: gzip" http://localhost:7071/api/payload/large -o /dev/null

# No compression — below threshold
curl -s -D- -H "Accept-Encoding: gzip" http://localhost:7071/api/payload/small -o /dev/null

# No compression — no Accept-Encoding
curl -s -D- http://localhost:7071/api/payload/large -o /dev/null

# Control endpoint — never compressed
curl -s -D- http://localhost:7071/api/payload-no-gzip/large -o /dev/null

# Cache bypass
curl -s -D- -H "Accept-Encoding: gzip" -H "Cache-Control: no-cache" http://localhost:7071/api/payload/large -o /dev/null
```

## Deploy and test against APIM

```bash
# 1. Provision infrastructure (if not done yet)
./infra-up.sh

# 2. Deploy the function code
FUNCTION_NAME=func-apim-gzip-test RESOURCE_GROUP_NAME=rg-apim-gzip-test ./deploy.sh

# 3. Run the full test matrix against APIM, including build + deploy
FUNCTION_NAME=func-apim-gzip-test RESOURCE_GROUP_NAME=rg-apim-gzip-test \
ENDPOINT="https://apim-gzip-test.azure-api.net/gzip-test" ./run.sh

# 4. Or skip build + deploy and only run tests against an already deployed app
ENDPOINT="https://apim-gzip-test.azure-api.net/gzip-test" SKIP_DEPLOY=true ./run.sh

# 5. Tear down when done
./infra-down.sh
```

Important notes:

- `./run.sh` **does build + deploy by default** unless `SKIP_DEPLOY=true` is set.
- `ENDPOINT` must be the full request base prefix:
    - Direct Function App: `https://func-apim-gzip-test.azurewebsites.net/api`
    - APIM: `https://apim-gzip-test.azure-api.net/gzip-test`
- Do **not** include the final route segment in `ENDPOINT`. The script appends `/payload/{size}` or `/payload-no-gzip/{size}` itself.

## Expected results

When testing through APIM with external Redis cache:

- **Non-gzip responses**: cache MISS and cache HIT should return identical `Content-Length` and body sizes
- **Gzip responses below 1 MB compressed**: should work correctly (small, medium are below compress threshold so not gzip'd)
- **Gzip responses above 1 MB compressed**: cache HIT may return truncated payload (~1.8-1.9 MB decompressed regardless of original size)

## Current mitigation in production

Compression is disabled in `retail-platform-global-services` (commit `0d03d8d8df7f617d9bd075ba4697e9744f1bf664`). See the comment in `application/common/packages/fastify/fastify/src/plugins/root.ts`:

> DRO-30276: gzip compression is disabled. Azure APIM strips Content-Length from compressed responses and serves them as chunked transfer. On a cache HIT, the Redis B0 external cache truncates the chunked gzip stream, delivering a corrupt and incomplete response to the client.
