#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# run.sh — deploy and run the APIM gzip cache truncation test matrix
#
# Prerequisites:
#   - Azure Function App deployed (or let this script build + deploy it)
#   - APIM instance with external Redis cache and cache policy applied
#   - Set ENDPOINT to the full base URL prefix used for requests
#     Examples:
#       - Direct Function: https://func-apim-gzip-test.azurewebsites.net/api
#       - APIM:            https://apim-gzip-test.azure-api.net/gzip-test
#
# Environment variables:
#   RESOURCE_GROUP_NAME  — Azure resource group (default: rg-apim-gzip-test)
#   FUNCTION_NAME        — Azure Function App name (default: func-apim-gzip-test)
#   ENDPOINT             — Base URL prefix to test against
#   SKIP_DEPLOY          — Set to "true" to skip the build + deploy step
###############################################################################

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-apim-gzip-test}"
FUNCTION_NAME="${FUNCTION_NAME:-func-apim-gzip-test}"
ENDPOINT="${ENDPOINT:-https://${FUNCTION_NAME}.azurewebsites.net/api}"
SKIP_DEPLOY="${SKIP_DEPLOY:-false}"
RESULTS_FILE="assets/results.md"

# Preconditions
for bin in curl node npm; do
  command -v "$bin" >/dev/null || {
    echo "Missing required tool: $bin"
    exit 1
  }
done

# Build + deploy unless skipped
if [[ "$SKIP_DEPLOY" != "true" ]]; then
  echo "==> Building and deploying function app before running tests..."
  ./deploy.sh
fi

mkdir -p assets

# ---------------------------------------------------------------------------
# Test matrix
# ---------------------------------------------------------------------------

SIZES=(small medium large xlarge xxlarge)
PATHS=("payload" "payload-no-gzip" "fastify-payload" "fastify-payload-no-gzip")
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

{
  echo "# APIM gzip cache truncation — test results"
  echo ""
  echo "Endpoint: \`${ENDPOINT}\`"
  echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
  echo "## Results"
  echo ""
  echo "| Path | Size | Accept-Enc | Run | HTTP | Content-Length | Content-Encoding | Body bytes | Decompressed bytes | X-Payload-Uncompressed-Size | X-Payload-Compressed | X-Response-Timestamp |"
  echo "|------|------|------------|-----|------|----------------|-----------------|------------|--------------------|-----------------------------|----------------------|----------------------|"
} > "$RESULTS_FILE"

do_request() {
  local path="$1"
  local size="$2"
  local accept_enc="$3"
  local label="$4"
  local extra_headers=("${@:5}")
  local base_url="${ENDPOINT%/}"
  local url="${base_url}/${path}/${size}"

  local curl_args=(-s -o "$TMPFILE" -D /dev/fd/3 -w '%{http_code}')
  if [[ -n "$accept_enc" ]]; then
    curl_args+=(-H "Accept-Encoding: ${accept_enc}")
  fi
  for h in "${extra_headers[@]+"${extra_headers[@]}"}"; do
    curl_args+=(-H "$h")
  done

  # Capture headers to variable via fd 3
  local headers http_code
  exec 3>&1
  http_code=$(curl "${curl_args[@]}" "$url" 3>"$TMPFILE.headers") || true
  headers=$(cat "$TMPFILE.headers" 2>/dev/null || echo "")
  rm -f "$TMPFILE.headers"

  local body_size
  body_size=$(wc -c < "$TMPFILE" | tr -d ' ')

  local content_length content_encoding x_uncompressed x_compressed x_response_ts decompressed_size
  content_length=$(echo "$headers" | grep -i '^content-length:' | head -1 | awk '{print $2}' | tr -d '\r' || echo "-")
  content_encoding=$(echo "$headers" | grep -i '^content-encoding:' | head -1 | awk '{print $2}' | tr -d '\r' || echo "-")
  x_uncompressed=$(echo "$headers" | grep -i '^x-payload-uncompressed-size:' | head -1 | awk '{print $2}' | tr -d '\r' || echo "-")
  x_compressed=$(echo "$headers" | grep -i '^x-payload-compressed:' | head -1 | awk '{print $2}' | tr -d '\r' || echo "-")
  x_response_ts=$(echo "$headers" | grep -i '^x-response-timestamp:' | head -1 | awk '{print $2}' | tr -d '\r' || echo "-")

  decompressed_size="-"
  if file "$TMPFILE" 2>/dev/null | grep -q gzip; then
    decompressed_size=$(gunzip -c "$TMPFILE" 2>/dev/null | wc -c | tr -d ' ' || echo "ERROR")
  fi

  [[ -z "$content_length" ]] && content_length="-"
  [[ -z "$content_encoding" ]] && content_encoding="-"

  echo "| ${path} | ${size} | ${accept_enc:-none} | ${label} | ${http_code} | ${content_length} | ${content_encoding} | ${body_size} | ${decompressed_size} | ${x_uncompressed} | ${x_compressed} | ${x_response_ts} |" >> "$RESULTS_FILE"
  echo "  ${label}: ${path}/${size} enc=${accept_enc:-none} => HTTP ${http_code}, X-Response-Timestamp=${x_response_ts}, body=${body_size}, decompressed=${decompressed_size}, CL=${content_length}"
}

for path in "${PATHS[@]}"; do
  for size in "${SIZES[@]}"; do
    echo ""
    echo ">>> Testing ${path}/${size}"

    # Run 1: cache MISS (first request or after cache purge)
    # Send no-cache to ensure we bypass any existing cache
    do_request "$path" "$size" "gzip" "bypass" "Cache-Control: no-cache"

    # Small delay to let APIM process
    sleep 1

    # Run 2: cache MISS (first cacheable request)
    do_request "$path" "$size" "gzip" "miss"

    # Small delay for cache store
    sleep 2

    # Run 3: cache HIT
    do_request "$path" "$size" "gzip" "hit"

    echo ""
    echo ">>> Testing ${path}/${size} without Accept-Encoding"
    do_request "$path" "$size" "" "no-enc"
  done
done

{
  echo ""
  echo "## Key observations"
  echo ""
  echo "Compare **miss** vs **hit** rows for gzip-compressed responses (path=payload, size>=large)."
  echo "If cache HIT shows smaller body/decompressed bytes than cache MISS, the truncation bug is confirmed."
} >> "$RESULTS_FILE"

echo ""
echo "==> Results written to ${RESULTS_FILE}"
cat "$RESULTS_FILE"
