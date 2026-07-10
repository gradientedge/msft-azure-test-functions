#!/bin/bash
set -euo pipefail

# Deploy and test flex-per-instance-concurrency experiment
#
# This tests the Flex Consumption perInstanceConcurrency platform setting.
# Unlike maxConcurrentRequests (host.json), this is a platform-level setting
# configured via Azure CLI that controls how many HTTP requests each instance
# handles concurrently, and triggers scale-out when exceeded.
#
# Optional env vars (all have defaults):
#   SUBSCRIPTION_ID   - Azure subscription
#   RESOURCE_GROUP_NAME - Azure resource group
#   FUNCTION_NAME     - Function app name (Flex Consumption)
#   REGION            - Azure region
#   STORAGE_ACCOUNT   - Storage account name (auto-discovered if omitted)
#   REFERENCE_FUNCTION_NAME - Existing app from which to reuse AI connection string
#   APIM_ENDPOINT     - Existing APIM base URL (preferred for testing via APIM)
#   FUNCTION_ENDPOINT - Explicit function endpoint override

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-0ebbefb8-987e-4fcd-bbbc-41d704f2d586}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
FUNCTION_NAME="${FUNCTION_NAME:-azfe-per-instance-conc}"
REGION="${REGION:-westeurope}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-}"
REFERENCE_FUNCTION_NAME="${REFERENCE_FUNCTION_NAME:-azure-test-otel}"
APIM_ENDPOINT="${APIM_ENDPOINT:-}"
FUNCTION_ENDPOINT="${FUNCTION_ENDPOINT:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Using subscription: ${SUBSCRIPTION_ID}"
az account set --subscription "$SUBSCRIPTION_ID"

resolve_storage_account() {
  if [[ -n "$STORAGE_ACCOUNT" ]]; then
    return 0
  fi

  STORAGE_ACCOUNT="$(az storage account list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?kind=='StorageV2' || kind=='Storage'].name | [0]" \
    -o tsv 2>/dev/null || true)"

  if [[ -z "$STORAGE_ACCOUNT" ]]; then
    echo "Error: No storage account found in ${RESOURCE_GROUP_NAME}."
    echo "Set STORAGE_ACCOUNT explicitly, or create one first."
    exit 1
  fi

  echo "Auto-discovered storage account: ${STORAGE_ACCOUNT}"
}

ensure_function_app_exists() {
  if az functionapp show --resource-group "$RESOURCE_GROUP_NAME" --name "$FUNCTION_NAME" >/dev/null 2>&1; then
    echo "Function app ${FUNCTION_NAME} already exists, reusing it."
    return 0
  fi

  resolve_storage_account
  echo "Creating Function App ${FUNCTION_NAME} in ${RESOURCE_GROUP_NAME}..."
  az functionapp create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_NAME" \
    --storage-account "$STORAGE_ACCOUNT" \
    --flexconsumption-location "$REGION" \
    --runtime node \
    --runtime-version 22
}

resolve_app_insights_connection_string() {
  local existing_value

  existing_value="$(az functionapp config appsettings list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_NAME" \
    --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING'].value | [0]" \
    -o tsv 2>/dev/null || true)"

  if [[ -n "$existing_value" ]]; then
    printf '%s' "$existing_value"
    return 0
  fi

  az functionapp config appsettings list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$REFERENCE_FUNCTION_NAME" \
    --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING'].value | [0]" \
    -o tsv 2>/dev/null || true
}

echo "=== flex-per-instance-concurrency ==="
echo ""

# Build
echo "Building..."
if [[ ! -d node_modules ]]; then
  npm install --no-audit --fund=false
else
  echo "Using existing node_modules"
fi
npm run build

# Deploy & configure
ensure_function_app_exists
echo ""
echo "Setting OTEL preload app setting..."
ai_connection_string="$(resolve_app_insights_connection_string)"
if [[ -n "$ai_connection_string" ]]; then
  az functionapp config appsettings set \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_NAME" \
    --settings \
    "languageWorkers__node__arguments=--require ./dist/src/opentelemetry.js" \
    "APPLICATIONINSIGHTS_CONNECTION_STRING=$ai_connection_string" >/dev/null
else
  echo "Warning: could not resolve APPLICATIONINSIGHTS_CONNECTION_STRING."
  az functionapp config appsettings set \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_NAME" \
    --settings \
    "languageWorkers__node__arguments=--require ./dist/src/opentelemetry.js" >/dev/null
fi

echo ""
echo "Waiting 10s for settings to propagate..."
sleep 10

echo "Deploying to ${FUNCTION_NAME} in ${RESOURCE_GROUP_NAME}..."
func azure functionapp publish "$FUNCTION_NAME" --javascript

echo ""
echo "Configuring perInstanceConcurrency=2..."
az functionapp scale config set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$FUNCTION_NAME" \
  --trigger-type http \
  --trigger-settings perInstanceConcurrency=2

echo ""
echo "Current scale config:"
az functionapp scale config show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$FUNCTION_NAME" \
  --output table

echo ""
echo "Waiting 15s for config to propagate..."
sleep 15

# Test
if [[ -n "$APIM_ENDPOINT" ]]; then
  FUNCTION_ENDPOINT="$APIM_ENDPOINT"
fi

if [[ -z "$FUNCTION_ENDPOINT" ]]; then
  host_name="$(az functionapp show \
    --name "$FUNCTION_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "properties.defaultHostName" -o tsv)"
  FUNCTION_ENDPOINT="https://${host_name}"
fi

echo ""
echo "Testing against: ${FUNCTION_ENDPOINT}/api/http-slow"
echo ""

# Test 1: Within limit (2 requests, perInstanceConcurrency=2)
echo "--- Test 1: 2 concurrent requests (within single instance limit) ---"
node test-per-instance.js "${FUNCTION_ENDPOINT}/api/http-slow" 2 3000 2

# Test 2: Exceed limit (5 requests, should need 3 instances)
echo ""
echo "--- Test 2: 5 concurrent requests (should trigger scale-out to 3 instances) ---"
node test-per-instance.js "${FUNCTION_ENDPOINT}/api/http-slow" 5 3000 5

# Test 3: Higher load (8 requests, should need 4 instances)
echo ""
echo "--- Test 3: 8 concurrent requests (should trigger scale-out to 4 instances) ---"
node test-per-instance.js "${FUNCTION_ENDPOINT}/api/http-slow" 8 3000 3
