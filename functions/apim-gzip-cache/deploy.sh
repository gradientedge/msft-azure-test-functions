#!/usr/bin/env bash
set -euo pipefail

# Config (override via env)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-miron}"
FUNCTION_NAME="${FUNCTION_NAME:-azure-test-apim-gzip-cache}"

# Preconditions
for bin in az node npm func; do
  command -v "$bin" >/dev/null || {
    echo "Missing required tool: $bin"
    exit 1
  }
done

echo "==> Installing dependencies"
npm ci --prefer-offline

echo "==> Building"
npm run build

echo "==> Pruning dev dependencies for deployment package"
npm prune --omit=dev

echo "==> Publishing to ${FUNCTION_NAME}"
func azure functionapp publish "${FUNCTION_NAME}" --javascript

echo "==> Done"
