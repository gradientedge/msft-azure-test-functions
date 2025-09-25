#!/usr/bin/env bash
set -euo pipefail

# Config (override via env)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
FUNCTION_NAME="${FUNCTION_NAME:-azure-test-otel}"
VAULT_ENDPOINT="${VAULT_ENDPOINT:-https://really-secret.vault.azure.net/}"

# Preconditions
for bin in az curl node npm func; do
  command -v "$bin" >/dev/null || {
    echo "Missing required tool: $bin"
    exit 1
  }
done

echo "Cleaning and installing dev deps"
rm -rf dist
npm ci --prefer-offline

# Results header
{
  echo "# Experiment"
  echo
  echo "The purpose of the experiment is to test configuration for OTEL support."
  echo
  echo "Function setup:"
  echo "- npm"
   echo "- ESM module"
  echo "- dynamic-kv4_8 import"
  echo "- esbuild"
  echo
  echo "To execute experiment run below script:"
  echo "\`\`\`shell"
  echo "./run.sh"
  echo "\`\`\`"
  echo
  echo "## Environment"
  echo
  echo "\`\`\`text"
  echo "NODE:"
  node -v
  echo
  echo "NPM:"
  npm -v
  echo
  echo "FUNC:"
  func --version || true
  echo
  echo "AZ:"
  az version || true
  echo "\`\`\`"
  echo
  echo "## Dependencies"
  echo
  echo "\`\`\`text"
  npm ls || true
  echo "\`\`\`"
  echo "## Package size"
  echo
  echo "\`\`\`text"
  echo "REPLACE WITH VALUE"
  echo "\`\`\`"
} >README.md

echo "Building application"
npm run build




echo "Updating Function App settings (Node preload)"
# For CJS preload use -r, include source maps
APP_ARGS="--enable-source-maps"
az functionapp config appsettings set \
  --name "${FUNCTION_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --settings "languageWorkers__node__arguments=${APP_ARGS}" >/dev/null

echo "Waiting for app setting to apply..."
# Poll until setting is visible server-side (up to ~60s)
for _ in {1..30}; do
  val="$(az functionapp config appsettings list \
    --name "${FUNCTION_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --query "[?name=='languageWorkers__node__arguments'].value | [0]" -o tsv || true)"
  [[ "$val" == "$APP_ARGS" ]] && break
  sleep 2
done

az functionapp config appsettings set \
  --name "${FUNCTION_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --settings "VAULT_ENDPOINT=${VAULT_ENDPOINT}" >/dev/null

echo "Waiting for app setting to apply..."
# Poll until setting is visible server-side (up to ~60s)
for _ in {1..30}; do
  val="$(az functionapp config appsettings list \
    --name "${FUNCTION_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --query "[?name=='VAULT_ENDPOINT'].value | [0]" -o tsv || true)"
  [[ "$val" == "$VAULT_ENDPOINT" ]] && break
  sleep 2
done

sleep 15

echo "Deploying application"
pushd dist
# We already built JS; avoid TypeScript rebuild during publish
PUBLISH_OUTPUT=$(func azure functionapp publish "${FUNCTION_NAME}" --javascript 2>&1)
echo "$PUBLISH_OUTPUT"

# Extract bundle size from publish output
BUNDLE_SIZE=$(echo "$PUBLISH_OUTPUT" | grep -o "Uploading [0-9.]\+ MB" | head -1 || echo "Size not captured")
echo "Captured bundle size: $BUNDLE_SIZE"

popd
echo "Getting actual Function App endpoint"
ENDPOINT="$(az functionapp show \
  --name "${FUNCTION_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query "properties.defaultHostName" -o tsv)"

if [[ -n "$ENDPOINT" ]]; then
  ENDPOINT="https://${ENDPOINT}"
  echo "Updated ENDPOINT to: ${ENDPOINT}"
else
  echo "Error: Could not retrieve Function App endpoint, using configured value: ${ENDPOINT}"
  exit 1
fi

# Update README with actual bundle size
sed -i '' 's/REPLACE WITH VALUE/'"$BUNDLE_SIZE"'/g' README.md

echo "Measuring request timings"
{
  echo
  echo "## Request Timing"
  echo
  echo "| Time | Function | Traceparent | Response (seconds) |"
  echo "|---|---|---|---|"
} >>README.md

result=()

measure() {
  local path="$1"
  uri="${ENDPOINT}${path}"
  result=()
  while IFS= read -r line; do
    result+=("$line")
  done < <(
    curl -s -D - -o /dev/null -w "request_time: %{time_total}\n" "$uri" |
      awk -v IGNORECASE=1 '/^(traceparent|request_time):/ {print $2}'
  )
}

measure "/api/http"
echo "| $(date) | http | ${result[0]} | ${result[1]} |" >>README.md

measure "/api/http-with-keyvault"
echo "| $(date) | http-with-keyvault | ${result[0]} | ${result[1]} |" >>README.md

measure "/api/http-external-api"
echo "| $(date) | http-external-api | ${result[0]} | ${result[1]} |" >>README.md

{
  echo
  echo "## Trace"
  echo
  echo "## HTTP Trace"
  echo
  echo "![HTTP](assets/http.png)"
  echo
  echo "## HTTP Key Vault Trace"
  echo
  echo "![HTTP Key Vault](assets/http-with-keyvault.png)"
  echo
  echo "## HTTP External API Trace"
  echo
  echo "![HTTP External API](assets/http-external-api.png)"
  echo
  echo "## Observation"
  echo
} >>README.md

echo "Restoring dev deps for local development"
npm ci --prefer-offline

echo "Done. See README.md"
