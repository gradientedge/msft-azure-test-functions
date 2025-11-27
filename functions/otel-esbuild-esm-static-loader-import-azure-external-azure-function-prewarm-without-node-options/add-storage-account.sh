#!/usr/bin/env bash

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-playground-kamil}"
FUNCTION_NAME="${FUNCTION_NAME:-azure-test-otel}"
MOUNT_PATH="${MOUNT_PATH:-/mnt/otel-modules}"
LOCATION="${LOCATION:-westeurope}"
AZURE_STORAGE_ACCOUNT="otelnodemodules"
SKU_STORAGE="Standard_LRS"
SHARE="otel-node-modules"
DIRECTORY="otel-node-modules"
SHARE_ID="otel-node-modulues"

# Create an Azure storage account in the resource group.
echo "Creating $AZURE_STORAGE_ACCOUNT"
az storage account create --name "${AZURE_STORAGE_ACCOUNT}" --location "${LOCATION}" --resource-group "${RESOURCE_GROUP_NAME}" --sku "${SKU_STORAGE}"

# Set the storage account key as an environment variable.
export AZURE_STORAGE_KEY=$(az storage account keys list -g "${RESOURCE_GROUP_NAME}" -n "${AZURE_STORAGE_ACCOUNT}" --query '[0].value' -o tsv)

# Create a serverless function app in the resource group.
echo "Creating ${FUNCTION_NAME}"
az functionapp update --name ${FUNCTION_NAME} --storage-account $AZURE_STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP_NAME

# Work with Storage account using the set env variables.
# Create a share in Azure Files.
echo "Creating $SHARE"
az storage share create --name "$SHARE"

# Create a directory in the share.
echo "Creating $DIRECTORY in $SHARE"
az storage directory create --share-name "$SHARE" --name "$DIRECTORY"

# Create webapp config storage account
echo "Creating $AZURE_STORAGE_ACCOUNT"
az webapp config storage-account add \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name $FUNCTION_NAME \
  --custom-id ${SHARE_ID} \
  --storage-type AzureFiles \
  --share-name $SHARE \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --mount-path $MOUNT_PATH \
  --access-key $AZURE_STORAGE_KEY

# List webapp storage account
az webapp config storage-account list --resource-group "${RESOURCE_GROUP_NAME}" --name "${FUNCTION_NAME}"
