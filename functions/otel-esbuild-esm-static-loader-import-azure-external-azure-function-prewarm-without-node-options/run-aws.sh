#!/usr/bin/env bash
set -euo pipefail

unset LESS
# Config (override via env)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
FUNCTION_NAME="${FUNCTION_NAME:-azure-monitoring-function}"
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
  echo "- dynamic import"
  echo "- esbuild"
  echo "- KV Library 4.8"
  echo "- experimental loader"
  echo "- static import from package.json"
  echo "- external @azure/functions"
  echo "- prewarm function"
  echo "- disable languageWorkers__node__arguments"
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
aws lambda update-function-configuration \
  --function-name "${FUNCTION_NAME}" \
  --environment "Variables={APPLICATIONINSIGHTS_CONNECTION_STRING=<secret>,OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318/,OTEL_TRACES_EXPORTER=console,OTEL_METRICS_EXPORTER=console,OTEL_LOG_LEVEL=DEBUG,OTEL_TRACES_SAMPLER=always_on,AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-handler,OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/collector.yaml,OPENTELEMETRY_EXTENSION_LOG_LEVEL=debug}"
echo "Waiting for app setting to apply..."

sleep 15

echo "Deploying application"
pushd dist

# layers
# arn:aws:lambda:eu-west-1:184161586896:layer:opentelemetry-nodejs-0_17_0:1
# arn:aws:lambda:eu-west-1:184161586896:layer:opentelemetry-collector-arm64-0_18_0:1
rm -rf function
mkdir -p function/src
mkdir -p function/apps
cp ./dist/src/apps/http-with-keyvault-prewarm-aws.mjs function/index.mjs
cp ../collector.yaml function/
pushd function
zip -r function.zip .
popd

# We already built JS; avoid TypeScript rebuild during publish
aws lambda update-function-code \
  --function-name "${FUNCTION_NAME}" \
  --zip-file fileb://function/function.zip
# Extract bundle size from publish output
popd
echo "Getting actual Function App endpoint"
ENDPOINT="<replace-with-actual-endpoint>"

if [[ -n "$ENDPOINT" ]]; then
  ENDPOINT="https://${ENDPOINT}"
  echo "Updated ENDPOINT to: ${ENDPOINT}"
else
  echo "Error: Could not retrieve Function App endpoint, using configured value: ${ENDPOINT}"
  exit 1
fi

# Update README with actual bundle size

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

measure "/"
echo "$(date) | http-with-keyvault-prewarm | ${result[0]} | ${result[1]} |" >>README.md

{
  echo
  echo "## Trace"
  echo
  echo "## Full Trace"
  echo
  echo "![Full Trace](assets/cold-start.png)"
  echo
  echo "## Pre-warm up Trace"
  echo
  echo "![Pre-warm up](assets/prewarm-without-node-optionsup.png)"
  echo
  echo "## Logs"
  echo
  echo "[Logs](assets/logs.csv)"
  echo
  echo "## Observation"
  echo
} >>README.md

echo "Done. See README.md"
