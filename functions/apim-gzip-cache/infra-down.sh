#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# infra-down.sh — Tear down Azure infrastructure for the APIM gzip test
#
# Default (no args):
#   1. Removes gzip-test-api, external Redis cache config, and orphaned
#      named-values from the shared APIM (functionapimtest / playground-kamil).
#   2. Deletes the resource group rg-apim-gzip-test and everything in it
#      (Function App, Storage, Redis Enterprise).
#
# --function-only: deletes only the Function App.
###############################################################################

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-apim-gzip-test}"
FUNCTION_NAME="${FUNCTION_NAME:-func-apim-gzip-test}"
APIM_NAME="${APIM_NAME:-functionapimtest}"
APIM_RESOURCE_GROUP="${APIM_RESOURCE_GROUP:-playground-kamil}"
MODE="all"

if [[ "${1:-}" == "--function-only" ]]; then
  MODE="function-only"
elif [[ -n "${1:-}" ]]; then
  echo "Unknown argument: $1"
  echo "Usage: ./infra-down.sh [--function-only]"
  exit 1
fi

if [[ "$MODE" == "function-only" ]]; then
  echo "This will DELETE only the Function App '${FUNCTION_NAME}' in '${RESOURCE_GROUP}'."
  echo "Storage, Redis Enterprise, and APIM artifacts will remain unchanged."
  echo ""
  read -r -p "Are you sure? (y/N): " confirm

  if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 0
  fi

  echo "==> Deleting function app: ${FUNCTION_NAME}..."
  az functionapp delete \
    --name "$FUNCTION_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output none
  echo "    Function App deleted."
  exit 0
fi

echo "This will:"
echo "  1. REMOVE APIM artifacts from shared APIM '${APIM_NAME}' (${APIM_RESOURCE_GROUP})"
echo "       gzip-test-api API, external Redis cache config, orphaned named-values"
echo "  2. DELETE resource group '${RESOURCE_GROUP}' and ALL resources in it:"
echo "       Function App, Storage Account, Redis Enterprise cache"
echo ""
read -r -p "Are you sure? (y/N): " confirm

if [[ "${confirm,,}" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

SUB_ID=$(az account show --query id -o tsv)

# ── APIM artifacts (shared instance in a different resource group) ────────────

echo "==> Removing APIM artifacts from ${APIM_NAME} (${APIM_RESOURCE_GROUP})..."

if az apim api show \
  --resource-group "$APIM_RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --api-id "gzip-test-api" \
  --query name -o tsv >/dev/null 2>&1; then
  az apim api delete \
    --resource-group "$APIM_RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --api-id "gzip-test-api" \
    --delete-revisions true \
    --yes 2>/dev/null || true
  echo "    Deleted gzip-test-api"
else
  echo "    gzip-test-api not found, skipping."
fi

az rest \
  --method DELETE \
  --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/caches/default?api-version=2022-08-01" \
  --output none 2>/dev/null \
  && echo "    Deleted external Redis cache config" \
  || echo "    No external cache config found, skipping."

NV_IDS=$(az rest \
  --method GET \
  --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues?api-version=2022-08-01" \
  --query "value[?starts_with(properties.displayName,'cache-default-connection-')].name" \
  -o tsv 2>/dev/null || echo "")

if [[ -n "$NV_IDS" ]]; then
  while IFS= read -r nv_id; do
    [[ -z "$nv_id" ]] && continue
    az rest \
      --method DELETE \
      --uri "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${APIM_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues/${nv_id}?api-version=2022-08-01" \
      --output none 2>/dev/null && echo "    Deleted named-value: ${nv_id}"
  done <<< "$NV_IDS"
fi

# ── Resource Group ────────────────────────────────────────────────────────────

echo "==> Deleting resource group: ${RESOURCE_GROUP}..."
az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait

echo "==> Deletion initiated (runs in background). Check status with:"
echo "    az group show --name ${RESOURCE_GROUP} --query properties.provisioningState -o tsv"
