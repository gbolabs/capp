# Check if all required environment variables are set
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
 
echo "Azure Login"
# Login to Azure
az login -t $TENANT_ID --identity --username $IDENTITY_CLIENT_ID
az account set --subscription $SUBSCRIPTION_ID
 
# Get keyvault access token
KV_TOKEN=$(az account get-access-token --resource=https://vault.azure.net --query accessToken -o tsv)
 
# dump token first chars and last chars and length
echo "KV_TOKEN: ${KV_TOKEN:0:3}...${KV_TOKEN: -3}...${#KV_TOKEN}"
 
# Get keyvault secret
KV_SECRET=$(az keyvault secret show --name $SECRET_NAME --vault-name $VAULT_NAME --query value -o tsv --subscription $SUBSCRIPTION_ID --token $KV_TOKEN)
 
# dump secret first chars and last chars and length
echo "KV_SECRET: ${KV_SECRET:0:3}...${KV_SECRET: -3}...${#KV_SECRET}"