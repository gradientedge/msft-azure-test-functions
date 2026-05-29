#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# infra-up.sh — Provision Azure infrastructure for the APIM gzip cache test
#
# Creates:
#   1. Resource Group
#   2. Storage Account (required by Azure Functions)
#   3. Azure Function App (Node.js 22, Flex Consumption — matches production)
#   4. Redis Enterprise cache (Balanced_B0 — matches retail)
#   5. API Management instance (existing APIM can be reused; otherwise create)
#   6. APIM external cache pointing to Redis
#   7. APIM API + operations + cache policies
#
# Override defaults via environment variables.
###############################################################################

# ── Configuration ────────────────────────────────────────────────────────────

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-apim-gzip-test}"
LOCATION="${LOCATION:-westeurope}"
FUNCTION_NAME="${FUNCTION_NAME:-func-apim-gzip-test}"
STORAGE_NAME="${STORAGE_NAME:-}"
REDIS_NAME="${REDIS_NAME:-redis-apim-gzip-test}"
APIM_NAME="${APIM_NAME:-functionapimtest}"
APIM_RESOURCE_GROUP="${APIM_RESOURCE_GROUP:-playground-kamil}"
APIM_PUBLISHER_EMAIL="${APIM_PUBLISHER_EMAIL:-admin@example.com}"
APIM_PUBLISHER_NAME="${APIM_PUBLISHER_NAME:-APIM Gzip Test}"
REDIS_SKU="${REDIS_SKU:-Balanced_B0}"
API_PATH="gzip-test"

# ── Preconditions ────────────────────────────────────────────────────────────

for bin in az jq; do
  command -v "$bin" >/dev/null || { echo "Missing required tool: $bin"; exit 1; }
done

if ! az extension show --name redisenterprise >/dev/null 2>&1; then
  az extension add --name redisenterprise --upgrade --yes --only-show-errors >/dev/null
fi

echo "==> All resources will be created in:"
echo "    Resource Group : ${RESOURCE_GROUP}"
echo "    Location       : ${LOCATION}"
echo ""

# ── 1. Resource Group ────────────────────────────────────────────────────────

echo "==> Creating resource group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# ── 2. Storage Account ──────────────────────────────────────────────────────

# Determine storage account name in a rerun-safe way:
# 1) use STORAGE_NAME if provided,
# 2) else reuse Function App storage account if Function App already exists,
# 3) else reuse an existing test storage account in this resource group,
# 4) else create a new random one.
if [[ -z "$STORAGE_NAME" ]]; then
  if az functionapp show --name "$FUNCTION_NAME" --resource-group "$RESOURCE_GROUP" --query name -o tsv >/dev/null 2>&1; then
    EXISTING_STORAGE_CONN=$(az functionapp config appsettings list \
      --name "$FUNCTION_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --query "[?name=='AzureWebJobsStorage'].value | [0]" -o tsv 2>/dev/null || true)
    STORAGE_NAME=$(echo "$EXISTING_STORAGE_CONN" | sed -n 's/.*AccountName=\([^;]*\).*/\1/p')
  fi

  if [[ -z "$STORAGE_NAME" ]]; then
    STORAGE_NAME=$(az storage account list \
      --resource-group "$RESOURCE_GROUP" \
      --query "[?starts_with(name, 'stapimgziptest')].name | [0]" -o tsv 2>/dev/null || true)
    if [[ "$STORAGE_NAME" == "null" ]]; then
      STORAGE_NAME=""
    fi
  fi

  if [[ -z "$STORAGE_NAME" ]]; then
    STORAGE_NAME="stapimgziptest$(openssl rand -hex 3)"
  fi
fi

# Storage name must be 3-24 lowercase alphanumeric chars, globally unique.
STORAGE_NAME=$(echo "$STORAGE_NAME" | tr -cd 'a-z0-9' | head -c 24)

echo "==> Ensuring storage account exists: ${STORAGE_NAME}..."
if az storage account show --name "$STORAGE_NAME" --resource-group "$RESOURCE_GROUP" --query name -o tsv >/dev/null 2>&1; then
  echo "    Storage account already exists, skipping create."
else
  az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --tags purpose=apim-gzip-test managed-by=infra-up \
    --output none
fi

# ── 3. Function App (Flex Consumption — matches production) ─────────────────

echo "==> Creating function app: ${FUNCTION_NAME} (Flex Consumption)..."
if az functionapp show --name "$FUNCTION_NAME" --resource-group "$RESOURCE_GROUP" --query name -o tsv >/dev/null 2>&1; then
  echo "    Function app already exists, skipping create."
else
  az functionapp create \
    --name "$FUNCTION_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --storage-account "$STORAGE_NAME" \
    --flexconsumption-location "$LOCATION" \
    --runtime node \
    --runtime-version 22 \
    --functions-version 4 \
    --output none
fi

echo "    Function URL: https://${FUNCTION_NAME}.azurewebsites.net"

# ── 4. Redis Enterprise cache ────────────────────────────────────────────────

echo "==> Creating Redis Enterprise cache: ${REDIS_NAME} (${REDIS_SKU})..."
EXISTING_REDIS_STATE=$(az redisenterprise show \
  --cluster-name "$REDIS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "provisioningState" -o tsv 2>/dev/null || echo "")

if [[ "$EXISTING_REDIS_STATE" == "Succeeded" ]]; then
  echo "    Redis Enterprise cache already exists, skipping create."
else
  # Delete any stuck resource (CreateFailed, etc.) before recreating.
  if [[ -n "$EXISTING_REDIS_STATE" ]]; then
    echo "    Redis exists in state '${EXISTING_REDIS_STATE}', deleting stuck resource..."
    az redisenterprise delete \
      --cluster-name "$REDIS_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --yes --output none
    echo "    Waiting for deletion to complete..."
    for _del in $(seq 1 30); do
      az redisenterprise show --cluster-name "$REDIS_NAME" --resource-group "$RESOURCE_GROUP" \
        --query name -o tsv >/dev/null 2>&1 || break
      sleep 10
    done
  fi

  # Balanced_B0 enables zone redundancy automatically; do not specify --capacity or --zones.
  az redisenterprise create \
    --cluster-name "$REDIS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku "$REDIS_SKU" \
    --minimum-tls-version 1.2 \
    --public-network-access Enabled \
    --access-keys-auth Enabled \
    --output none
fi

echo "==> Waiting for Redis to finish provisioning..."
for attempt in $(seq 1 90); do
  REDIS_STATE=$(az redisenterprise show \
    --cluster-name "$REDIS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")

  if [[ "$REDIS_STATE" == "Succeeded" ]]; then
    echo "    Redis provisioning state: ${REDIS_STATE}"
    break
  fi

  if [[ "$REDIS_STATE" == "Failed" ]]; then
    echo "Redis provisioning failed. Check resource status in Azure Portal."
    exit 1
  fi

  echo "    Redis provisioning state: ${REDIS_STATE} (attempt ${attempt}/90)"
  sleep 10
done

if [[ "${REDIS_STATE:-Unknown}" != "Succeeded" ]]; then
  echo "Timed out waiting for Redis provisioning to complete."
  exit 1
fi

REDIS_HOST=$(az redisenterprise show \
  --cluster-name "$REDIS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "hostName" -o tsv)

REDIS_KEY=$(az redisenterprise database list-keys \
  --cluster-name "$REDIS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "primaryKey" -o tsv)

REDIS_PORT=$(az redisenterprise database show \
  --cluster-name "$REDIS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "port" -o tsv)

REDIS_CONNECTION_STRING="${REDIS_HOST}:${REDIS_PORT},password=${REDIS_KEY},ssl=True,abortConnect=False"
echo "    Redis host: ${REDIS_HOST}"

# ── 5. API Management ───────────────────────────────────────────────────────
# Reuses an existing APIM instance; creates a new Consumption-tier one only if
# the named instance does not exist in APIM_RESOURCE_GROUP.

echo "==> Ensuring APIM instance exists: ${APIM_NAME}..."
if az apim show --name "$APIM_NAME" --resource-group "$APIM_RESOURCE_GROUP" --query name -o tsv >/dev/null 2>&1; then
  echo "    APIM instance already exists, skipping create."
else
  az apim create \
    --name "$APIM_NAME" \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --location "$LOCATION" \
    --publisher-email "$APIM_PUBLISHER_EMAIL" \
    --publisher-name "$APIM_PUBLISHER_NAME" \
    --sku-name Consumption \
    --output none
fi

echo "    APIM Gateway URL: https://${APIM_NAME}.azure-api.net"

# ── 6. APIM external cache (Redis) ──────────────────────────────────────────
#
# NOTE: Every PUT to /caches/default creates a new named-value for the
# connection string.  We always push (to refresh the connection after any
# policy update or APIM host recycle that stales the Redis pool), then delete
# all orphaned named-values left by previous runs.

echo "==> Configuring APIM external cache (Redis)..."
SUB_ID=$(az account show --query id -o tsv)
APIM_CACHE_LOCATION=$(az account list-locations --query "[?name=='${LOCATION}'].displayName | [0]" -o tsv 2>/dev/null || echo "${LOCATION}")

# Collect existing named-value IDs before the push so we can delete them after.
OLD_NV_IDS=$(az rest \
  --method GET \
  --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues?api-version=2022-08-01" \
  --query "value[?starts_with(properties.displayName,'cache-default-connection-')].name" \
  -o tsv 2>/dev/null || echo "")

az rest \
  --method PUT \
  --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/caches/default?api-version=2022-08-01" \
  --output none \
  --body "{
    \"properties\": {
      \"connectionString\": \"${REDIS_CONNECTION_STRING}\",
      \"description\": \"External Redis cache for gzip truncation test\",
      \"useFromLocation\": \"${APIM_CACHE_LOCATION}\"
    }
  }"

echo "    Redis connection string pushed (refreshes APIM connection pool)."

# Delete all named-values that existed before the push (they are now orphaned).
if [[ -n "$OLD_NV_IDS" ]]; then
  while IFS= read -r nv_id; do
    [[ -z "$nv_id" ]] && continue
    az rest \
      --method DELETE \
      --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues/${nv_id}?api-version=2022-08-01" \
      --output none 2>/dev/null && echo "    Deleted old named-value: ${nv_id}"
  done <<< "$OLD_NV_IDS"
fi

# ── 7. APIM API + operations + cache policy ─────────────────────────────────

BACKEND_URL="https://${FUNCTION_NAME}.azurewebsites.net/api"

echo "==> Creating APIM API..."
if az apim api show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --query name -o tsv >/dev/null 2>&1; then
  echo "    APIM API already exists, skipping create."
else
  az apim api create \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --display-name "Gzip Cache Test" \
    --path "$API_PATH" \
    --protocols https \
    --service-url "$BACKEND_URL" \
    --subscription-required false \
    --only-show-errors \
    --output none
fi

echo "==> Creating API operations..."

# payload/{size} — gzip endpoint
if az apim api operation show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --operation-id "get-payload" \
  --query name -o tsv >/dev/null 2>&1; then
  echo "    Operation get-payload already exists, skipping create."
else
  az apim api operation create \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --operation-id "get-payload" \
    --display-name "Get Payload (gzip)" \
    --method GET \
    --url-template "/payload/{size}" \
    --template-parameters name=size type=string required=true \
    --output none
fi

# payload-no-gzip/{size} — control endpoint
if az apim api operation show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --operation-id "get-payload-no-gzip" \
  --query name -o tsv >/dev/null 2>&1; then
  echo "    Operation get-payload-no-gzip already exists, skipping create."
else
  az apim api operation create \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --operation-id "get-payload-no-gzip" \
    --display-name "Get Payload (no gzip)" \
    --method GET \
    --url-template "/payload-no-gzip/{size}" \
    --template-parameters name=size type=string required=true \
    --output none
fi

# fastify-payload/{size} — Fastify adapter gzip endpoint (matches retail architecture)
if az apim api operation show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --operation-id "get-fastify-payload" \
  --query name -o tsv >/dev/null 2>&1; then
  echo "    Operation get-fastify-payload already exists, skipping create."
else
  az apim api operation create \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --operation-id "get-fastify-payload" \
    --display-name "Get Fastify Payload (gzip)" \
    --method GET \
    --url-template "/fastify-payload/{size}" \
    --template-parameters name=size type=string required=true \
    --output none
fi

# fastify-payload-no-gzip/{size} — Fastify adapter control endpoint
if az apim api operation show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --operation-id "get-fastify-payload-no-gzip" \
  --query name -o tsv >/dev/null 2>&1; then
  echo "    Operation get-fastify-payload-no-gzip already exists, skipping create."
else
  az apim api operation create \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --operation-id "get-fastify-payload-no-gzip" \
    --display-name "Get Fastify Payload (no gzip)" \
    --method GET \
    --url-template "/fastify-payload-no-gzip/{size}" \
    --template-parameters name=size type=string required=true \
    --output none
fi

echo "==> Applying cache policies..."

# The policy matches production retail-platform-global-services APIM policy.
# Applied at API level so it covers all operations.
POLICY_XML=$(cat <<'XML'
<policies>
  <inbound>
    <base />
    <set-variable name="cacheControlHeader" value='@(context.Request.Headers.GetValueOrDefault("Cache-Control", "").ToLower())' />
    <choose>
      <when condition='@(!((string)context.Variables["cacheControlHeader"]).Contains("no-cache"))'>
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" must-revalidate="false" downstream-caching-type="public" caching-type="external">
          <vary-by-header>Accept-Encoding</vary-by-header>
          <vary-by-query-parameter>id</vary-by-query-parameter>
        </cache-lookup>
      </when>
    </choose>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
    <choose>
      <when condition='@(((context.Response.StatusCode >= 200 &amp;&amp; context.Response.StatusCode &lt; 300) || context.Response.StatusCode == 404) &amp;&amp; !((string)context.Variables["cacheControlHeader"]).Contains("no-store"))'>
        <choose>
          <when condition='@{ var contentLength = context.Response.Headers.GetValueOrDefault("Content-Length", "0"); int length; return !int.TryParse(contentLength, out length) || length &lt;= 2000000; }'>
            <cache-store duration='@{
              var header = context.Response.Headers.GetValueOrDefault("Cache-Control", "");
              var maxAge = Regex.Match(header, @"max-age=(?&lt;maxAge&gt;\d+)").Groups["maxAge"]?.Value;
              return (!string.IsNullOrEmpty(maxAge)) ? int.Parse(maxAge) : 300; }' />
          </when>
        </choose>
      </when>
    </choose>
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
)

# Apply policy at API level
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az rest \
  --method PUT \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/apis/gzip-test-api/policies/policy?api-version=2022-08-01" \
  --output none \
  --body "{
    \"properties\": {
      \"format\": \"xml\",
      \"value\": $(echo "$POLICY_XML" | jq -Rs .)
    }
  }"

# ── 7b. Re-push Redis connection after policy (policy push resets APIM's Redis
#       connection pool; re-pushing restores it so cache is immediately usable) ──
#
# NOTE: After this push, APIM takes ~4 minutes to establish the new connection.
# Cache reads will fail (MISS) during that window; writes succeed immediately.
# Cache HITs appear ~10 seconds after the last write to a given key once the
# connection is established.

echo "==> Re-pushing Redis connection string after policy update..."
OLD_NV_IDS=$(az rest \
  --method GET \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues?api-version=2022-08-01" \
  --query "value[?starts_with(properties.displayName,'cache-default-connection-')].name" \
  -o tsv 2>/dev/null || echo "")

az rest \
  --method PUT \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/caches/default?api-version=2022-08-01" \
  --output none \
  --body "{
    \"properties\": {
      \"connectionString\": \"${REDIS_CONNECTION_STRING}\",
      \"description\": \"External Redis cache for gzip truncation test\",
      \"useFromLocation\": \"${APIM_CACHE_LOCATION}\"
    }
  }"

echo "    Redis connection string re-pushed."

if [[ -n "$OLD_NV_IDS" ]]; then
  while IFS= read -r nv_id; do
    [[ -z "$nv_id" ]] && continue
    az rest \
      --method DELETE \
      --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues/${nv_id}?api-version=2022-08-01" \
      --output none 2>/dev/null && echo "    Deleted old named-value: ${nv_id}"
  done <<< "$OLD_NV_IDS"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "==========================================================================="
echo " Infrastructure provisioned successfully!"
echo "==========================================================================="
echo ""
echo " Resource Group  : ${RESOURCE_GROUP}"
echo " Function App    : https://${FUNCTION_NAME}.azurewebsites.net"
echo " APIM Gateway    : https://${APIM_NAME}.azure-api.net"
echo " Test endpoint   : https://${APIM_NAME}.azure-api.net/${API_PATH}/payload/{size}"
echo " Control endpoint: https://${APIM_NAME}.azure-api.net/${API_PATH}/payload-no-gzip/{size}"
echo " Redis           : ${REDIS_HOST}"
echo ""
echo " Next steps:"
echo "   1. Deploy the function code:"
echo "      FUNCTION_NAME=${FUNCTION_NAME} RESOURCE_GROUP_NAME=${RESOURCE_GROUP} ./deploy.sh"
echo ""
echo "   2. Run the test matrix:"
echo "      ENDPOINT=https://${APIM_NAME}.azure-api.net/${API_PATH} SKIP_DEPLOY=true ./run.sh"
echo ""
echo "   3. Manual test:"
echo "      curl -s -D- -H 'Accept-Encoding: gzip' https://${APIM_NAME}.azure-api.net/${API_PATH}/payload/large -o /tmp/test.gz"
echo ""
echo "   4. Tear down when done:"
echo "      RESOURCE_GROUP=${RESOURCE_GROUP} ./infra-down.sh"
echo ""
