#!/bin/bash
set -euo pipefail

# Deployment script for both concurrency experiments
#
# Creates a Flex Consumption function app and deploys both experiments.
# Run this once to set up the Azure resources.
#
# Optional env vars (defaults reuse existing shared resources):
#   SUBSCRIPTION_ID    - Azure subscription
#   RESOURCE_GROUP_NAME - Azure resource group
#   REGION              - Azure region
#   STORAGE_ACCOUNT     - required only when app must be created
#   THROTTLE_FUNC_NAME  - Function app name for throttle experiment
#   PER_INSTANCE_FUNC_NAME - Function app name for per-instance experiment
#   REFERENCE_FUNCTION_NAME - Existing app from which to reuse AI connection string
#   THROTTLE_ALWAYS_READY_HTTP - Always-ready HTTP instances for throttle app
#   THROTTLE_MAX_INSTANCE_COUNT - Max instances cap for throttle app

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-0ebbefb8-987e-4fcd-bbbc-41d704f2d586}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
REGION="${REGION:-westeurope}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-}"

THROTTLE_FUNC_NAME="${THROTTLE_FUNC_NAME:-azfe-concurrency-throttle}"
PER_INSTANCE_FUNC_NAME="${PER_INSTANCE_FUNC_NAME:-azfe-per-instance-conc}"
REFERENCE_FUNCTION_NAME="${REFERENCE_FUNCTION_NAME:-azure-test-otel}"
THROTTLE_ALWAYS_READY_HTTP="${THROTTLE_ALWAYS_READY_HTTP:-2}"
THROTTLE_MAX_INSTANCE_COUNT="${THROTTLE_MAX_INSTANCE_COUNT:-2}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Deploying Concurrency Experiments ==="
echo "Subscription: ${SUBSCRIPTION_ID}"
echo "Resource Group: ${RESOURCE_GROUP_NAME}"
echo "Region: ${REGION}"
echo ""

az account set --subscription "$SUBSCRIPTION_ID"

resolve_storage_account() {
  if [[ -n "$STORAGE_ACCOUNT" ]]; then
    return 0
  fi

  # Reuse an existing storage account from the target resource group.
  STORAGE_ACCOUNT="$(az storage account list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?kind=='StorageV2' || kind=='Storage'].name | [0]" \
    -o tsv 2>/dev/null || true)"

  if [[ -n "$STORAGE_ACCOUNT" ]]; then
    echo "Auto-discovered storage account: ${STORAGE_ACCOUNT}"
    return 0
  fi

  echo "Error: No storage account found in resource group ${RESOURCE_GROUP_NAME}."
  echo "Set STORAGE_ACCOUNT explicitly, or create one first."
  exit 1
}

resolve_app_insights_connection_string() {
  local target_name="$1"
  local existing_value

  existing_value="$(az functionapp config appsettings list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$target_name" \
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

apply_runtime_settings() {
  local target_name="$1"
  local ai_connection_string

  ai_connection_string="$(resolve_app_insights_connection_string "$target_name")"

  if [[ -z "$ai_connection_string" ]]; then
    echo "Warning: could not resolve APPLICATIONINSIGHTS_CONNECTION_STRING for ${target_name}."
    echo "OTEL exporter will fail until the setting is configured."
  fi

  if [[ -n "$ai_connection_string" ]]; then
    az functionapp config appsettings set \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --name "$target_name" \
      --settings \
      "languageWorkers__node__arguments=--require ./dist/src/opentelemetry.js" \
      "APPLICATIONINSIGHTS_CONNECTION_STRING=$ai_connection_string" >/dev/null
  else
    az functionapp config appsettings set \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --name "$target_name" \
      --settings \
      "languageWorkers__node__arguments=--require ./dist/src/opentelemetry.js" >/dev/null
  fi
}

# --- Experiment 1: flex-concurrency-throttle ---
echo "--- Creating ${THROTTLE_FUNC_NAME} (Flex Consumption) ---"
if az functionapp show --resource-group "$RESOURCE_GROUP_NAME" --name "$THROTTLE_FUNC_NAME" >/dev/null 2>&1; then
  echo "Function app ${THROTTLE_FUNC_NAME} already exists, reusing it."
else
  resolve_storage_account
  az functionapp create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$THROTTLE_FUNC_NAME" \
    --storage-account "$STORAGE_ACCOUNT" \
    --flexconsumption-location "$REGION" \
    --runtime node \
    --runtime-version 22
fi

echo "Building & deploying flex-concurrency-throttle..."
cd "$SCRIPT_DIR/flex-concurrency-throttle"
if [[ ! -d node_modules ]]; then
  npm install --no-audit --fund=false
else
  echo "Using existing node_modules"
fi
npm run build

echo "Setting app settings for OTEL preload..."
apply_runtime_settings "$THROTTLE_FUNC_NAME"
echo "Configuring throttle app scale: always-ready http=${THROTTLE_ALWAYS_READY_HTTP}, max instances=${THROTTLE_MAX_INSTANCE_COUNT}"
az functionapp scale config always-ready set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$THROTTLE_FUNC_NAME" \
  --settings "http=${THROTTLE_ALWAYS_READY_HTTP}" >/dev/null
az functionapp scale config set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$THROTTLE_FUNC_NAME" \
  --maximum-instance-count "$THROTTLE_MAX_INSTANCE_COUNT" >/dev/null
sleep 10
func azure functionapp publish "$THROTTLE_FUNC_NAME" --javascript

echo ""
echo "--- Creating ${PER_INSTANCE_FUNC_NAME} (Flex Consumption) ---"
if az functionapp show --resource-group "$RESOURCE_GROUP_NAME" --name "$PER_INSTANCE_FUNC_NAME" >/dev/null 2>&1; then
  echo "Function app ${PER_INSTANCE_FUNC_NAME} already exists, reusing it."
else
  resolve_storage_account
  az functionapp create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$PER_INSTANCE_FUNC_NAME" \
    --storage-account "$STORAGE_ACCOUNT" \
    --flexconsumption-location "$REGION" \
    --runtime node \
    --runtime-version 22
fi

echo "Building & deploying flex-per-instance-concurrency..."
cd "$SCRIPT_DIR/flex-per-instance-concurrency"
if [[ ! -d node_modules ]]; then
  npm install --no-audit --fund=false
else
  echo "Using existing node_modules"
fi
npm run build

echo "Setting app settings for OTEL preload..."
apply_runtime_settings "$PER_INSTANCE_FUNC_NAME"
sleep 10
func azure functionapp publish "$PER_INSTANCE_FUNC_NAME" --javascript

# Configure perInstanceConcurrency
echo ""
echo "Setting perInstanceConcurrency=2 on ${PER_INSTANCE_FUNC_NAME}..."
az functionapp scale config set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$PER_INSTANCE_FUNC_NAME" \
  --trigger-type http \
  --trigger-settings perInstanceConcurrency=2

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Endpoints:"
echo "  Throttle:      https://${THROTTLE_FUNC_NAME}.azurewebsites.net/api/http-slow"
echo "  Per-instance:  https://${PER_INSTANCE_FUNC_NAME}.azurewebsites.net/api/http-slow"
echo ""
echo "Run tests:"
echo "  cd flex-concurrency-throttle && node test-concurrency.js https://${THROTTLE_FUNC_NAME}.azurewebsites.net/api/http-slow 4 3"
echo "  cd flex-per-instance-concurrency && node test-per-instance.js https://${PER_INSTANCE_FUNC_NAME}.azurewebsites.net/api/http-slow 5 3000 5"
