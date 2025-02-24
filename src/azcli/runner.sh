#!/bin/bash

# Check if all required  environment variables are set
if [ -z "$TENANT_ID" ]; then
    echo "TENANT_ID is not set"
    exit 1
fi
 
if [ -z "$IDENTITY_CLIENT_ID" ]; then
    echo "IDENTITY_CLIENT_ID is not set"
    exit 1
fi
 
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "SUBSCRIPTION_ID is not set"
    exit 1
fi
 
if [ -z "$VAULT_NAME" ]; then
    echo "VAULT_NAME is not set"
    exit 1
fi
 
if [ -z "$SECRET_NAME" ]; then
    echo "SECRET_NAME is not set"
    exit 1
fi

echo "Dumping the environment variables"
echo "================================="
echo "TENANT_ID: $TENANT_ID"
echo "IDENTITY_CLIENT_ID: $IDENTITY_CLIENT_ID"
echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "VAULT_NAME: $VAULT_NAME"
echo "SECRET_NAME: $SECRET_NAME"


echo "Setting the dummy value for APPSETTING_WEBSITE_SITE_NAME"
echo "========================================================"
# https://github.com/Azure/azure-cli/issues/22677
# export APPSETTING_WEBSITE_SITE_NAME=DUMMY
# set a dummy value for APPSETTING_WEBSITE_SITE_NAME environment variable to avoid the error
export APPSETTING_WEBSITE_SITE_NAME=DUMMY
echo "APPSETTING_WEBSITE_SITE_NAME: $APPSETTING_WEBSITE_SITE_NAME"

# Wait a while
echo "Sleeping for 10 seconds"
sleep 10

echo "Azure Login"
echo "============"

# Login to Azure using the managed identity, catch the output and dump it
az login --identity --username $IDENTITY_CLIENT_ID
az account show
az account set --subscription $SUBSCRIPTION_ID
 
# Get keyvault access token
KV_TOKEN=$(az account get-access-token --resource=https://vault.azure.net --query accessToken -o tsv)
 
# dump token first chars and last chars and length
echo "KV_TOKEN: ${KV_TOKEN:0:3}...${KV_TOKEN: -3}...${#KV_TOKEN}"
 
# Get keyvault secret
KV_SECRET=$(az keyvault secret show --name $SECRET_NAME --vault-name $VAULT_NAME --query value -o tsv --subscription $SUBSCRIPTION_ID)

# dump secret first chars and last chars and length
echo "KV_SECRET: ${KV_SECRET:0:3}...${KV_SECRET: -3}...${#KV_SECRET}"