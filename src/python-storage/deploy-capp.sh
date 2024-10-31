#!/bin/bash

cae=cae-capplab-dev-02
capp=python-storage
acr=acrcapplabgbodev02.azurecr.io
image=capp/python-storage
rg=rg-capplab-gbo-dev-0
mid=id-capp-capplab-dev-02

# check if the container app already exists
id=$(az containerapp show --name $capp --resource-group $rg --query id --output tsv)
caeId=$(az containerapp env show --name $cae --resource-group $rg --query name --output tsv)
# managed identity client id 
midClientId=$(az identity show --name $mid --resource-group $rg --query clientId --output tsv)
image=$acr/$image:latest

echo "Container App ID: $id"
echo "CAE ID: $caeId"
echo "Managed Identity Client ID: $midClientId"

if [ -z "$id" ]; then
    # create the container app
    az containerapp create --name $capp --resource-group $rg \
        --image $image \
        --cpu 0.25 --memory 0.5 \
        --min-replicas 1 --max-replicas 1 \
        --environment $caeId \
        --registry-identity $midId --registry-server $acr \
        --env-vars AZURE_AUTH_TYPE=ManagedIdentity AZURE_CLIENT_ID=$midClientId \
        AZURE_STORAGE_ACCOUNT_URL=https://stcapplabgbodev02.blob.core.windows.net/ \
        AZURE_STORAGE_CONTAINER_NAME=test001 \
        --verbose
else
    # update the container app
    az containerapp update --name $capp --resource-group $rg \
        --set-env-vars AZURE_AUTH_TYPE=ManagedIdentity AZURE_CLIENT_ID=$midClientId \
        AZURE_STORAGE_ACCOUNT_URL=https://stcapplabgbodev02.blob.core.windows.net/ \
        AZURE_STORAGE_CONTAINER_NAME=test001 \
        --image $image --verbose
fi