# flex-concurrency-throttle

Tests whether `maxConcurrentRequests` / `maxOutstandingRequests` / `dynamicThrottlesEnabled` in `host.json` causes request queuing or HTTP 429 rejection in **Flex Consumption** function apps.

## Hypothesis

In our QA2 EMEA environment, we observed multi-second delays between request arrival and first dependency call in `azfem4iapicustomerservicegraphql`. The suspicion is that `host.json` settings:

```json
{
  "extensions": {
    "http": {
      "maxConcurrentRequests": 50,
      "maxOutstandingRequests": 100,
      "dynamicThrottlesEnabled": true
    }
  }
}
```

...are applied **globally** (not per-instance) in Flex Consumption, meaning with only 2-4 instances and high traffic, requests queue in the function host before reaching application code.

## Configuration (Restrictive for Testing)

```json
"maxConcurrentRequests": 6,
"maxOutstandingRequests": 10,
"dynamicThrottlesEnabled": true
```

Scale configuration used by this demo:
- `always-ready` for `http` group: `2` (two warm HTTP instances)
- maximum instance count: `2` (keeps topology stable while validating limits)

This means:
- Up to 6 HTTP requests execute concurrently per host process
- In this nested demo, one slot per active caller is consumed by `http-slow` while worker calls run
- Additional worker requests can queue while total outstanding remains under 10
- HTTP 429 appears when outstanding capacity is exceeded
- `dynamicThrottlesEnabled` may further reduce limits under CPU/memory pressure

With two warm instances, if limits were strictly global, throughput would stay close to a single-instance cap. If limits are per-instance, effective throughput should improve and queueing pressure should reduce under the same external load.

In the current demo shape (`http-slow` calling `http-worker`), the outer caller request also occupies host capacity. That is why queueing can appear even when your external load seems small.

Practical expectation for a single batch call with `concurrency=24` and `delay=2000`:
- first group near ~2s (no queue)
- second group near ~4s (buffered/queued)
- remaining tail may return 429/503 under pressure

Calibrated run that currently shows all 3 zones in this environment:

```bash
node test-concurrency.js https://azfe-concurrency-throttle.azurewebsites.net/api/http-slow 24 1 2000
```

## Local Test

```bash
npm ci && npm run build
npm start
# In another terminal:
node test-concurrency.js http://localhost:7071/api/http-slow 4 3
```

## Azure Deploy & Test

```bash
export RESOURCE_GROUP_NAME=your-rg
export FUNCTION_NAME=your-flex-func
export ENDPOINT=https://your-flex-func.azurewebsites.net
./run.sh
```

## What to Observe

1. **HTTP 429 responses**: Confirms requests exceed `maxOutstandingRequests`
2. **Elevated response times** (>2s for a 2s sleep): Indicates queuing
3. **Same instance ID**: Proves all requests hit one instance (no scale-out triggered)

## Key Questions to Answer

- Are these limits per-instance or global in Flex Consumption?
- Does `dynamicThrottlesEnabled` compound the issue?
- How does the platform respond — does it scale out or just reject?
