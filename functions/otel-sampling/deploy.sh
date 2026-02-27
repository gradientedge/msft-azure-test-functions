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

echo "Building application"
npm run build

# We already built JS; avoid TypeScript rebuild during publish
pushd dist
func azure functionapp publish "${FUNCTION_NAME}" --javascript
popd
