#!/usr/bin/env bash
set -euo pipefail

# Config (override via env)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
FUNCTION_NAME="${FUNCTION_NAME:-azure-test-otel}"
VAULT_ENDPOINT="${VAULT_ENDPOINT:-https://really-secret.vault.azure.net/}"

echo "Getting actual Function App endpoint"
ENDPOINT="$(az functionapp show \
  --name "${FUNCTION_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query "properties.defaultHostName" -o tsv)"

if [[ -n "$ENDPOINT" ]]; then
  ENDPOINT="https://${ENDPOINT}"
  echo "ENDPOINT to: ${ENDPOINT}"
else
  echo "Error: Could not retrieve Function App endpoint, using configured value: ${ENDPOINT}"
  exit 1
fi

result=()

measure() {
  local path="$1"
  uri="${ENDPOINT}${path}"
  echo "Measuring request timings for ${uri}"
  result=()
  while IFS= read -r line; do
    result+=("$line")
  done < <(
    curl -s -D - -o /dev/null -w "request_time: %{time_total}\n" "$uri" |
      awk -v IGNORECASE=1 '/^(traceparent|request_time):/ {print $2}'
  )
}

measure "/api/http-with-keyvault-prewarm"
echo "$(date) | http-with-keyvault-prewarm | ${result[0]} | ${result[1]} |" >>request.log
