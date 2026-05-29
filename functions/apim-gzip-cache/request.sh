#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# request.sh — manual test helper for APIM gzip cache experiment
#
# Usage:
#   ./request.sh <endpoint_base> <path> [extra_curl_args...]
#
# Examples:
#   # Local — gzip large payload
#   ./request.sh http://localhost:7071 /api/payload/large -H "Accept-Encoding: gzip"
#
#   # Local — no-gzip control
#   ./request.sh http://localhost:7071 /api/payload-no-gzip/large
#
#   # APIM — gzip, cache bypass
#   ./request.sh https://your-apim.azure-api.net/service/test /api/payload/large \
#     -H "Accept-Encoding: gzip" -H "Cache-Control: no-cache"
#
#   # Direct function — gzip xlarge
#   ./request.sh https://azure-test-apim-gzip-cache.azurewebsites.net /api/payload/xlarge \
#     -H "Accept-Encoding: gzip"
###############################################################################

ENDPOINT="${1:?Usage: ./request.sh <endpoint_base> <path> [extra_curl_args...]}"
PATH_SUFFIX="${2:?Usage: ./request.sh <endpoint_base> <path> [extra_curl_args...]}"
shift 2

URL="${ENDPOINT}${PATH_SUFFIX}"

echo ">>> GET ${URL}"
echo ""

# -s: silent, -o /dev/null: discard body, -D -: dump headers to stdout
# -w: print response body size
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

HTTP_CODE=$(curl -s -o "$TMPFILE" -w '%{http_code}' -D - "$URL" "$@" 2>&1 | tee /dev/stderr | head -1 | tr -d '\r\n')

BODY_SIZE=$(wc -c < "$TMPFILE" | tr -d ' ')

echo ""
echo "--- Summary ---"
echo "HTTP Status:    ${HTTP_CODE}"
echo "Body size:      ${BODY_SIZE} bytes"

# If the response was gzip, try to decompress and show decompressed size
if file "$TMPFILE" | grep -q gzip; then
  DECOMPRESSED_SIZE=$(gunzip -c "$TMPFILE" 2>/dev/null | wc -c | tr -d ' ')
  echo "Decompressed:   ${DECOMPRESSED_SIZE} bytes"
fi

echo ""
