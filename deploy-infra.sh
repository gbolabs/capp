location=switzerlandnorth
resourceGroup=rg-gbo-capplab-dev
subscription=199fc2c4-a57c-4049-afbe-e1831f4b2f6e

vnetAdressPrefix=192.168.0.0/16
subnetAdressPrefix=192.168.0.0/24
vnetName=vnet-gbo-capplab-dev
subnet=cae

containerRegistryName=acrgbocaplab
managedIdentityName=mi-gbo-capplab-dev

caeName=cae-gbo-capplab-dev

capIngressName=cap-ingress-gbo-capplab-dev
capApiName=cap-api-gbo-capplab-dev
capWebName=cap-web-gbo-capplab-dev

logAnalyticsWorkspaceName=law-gbo-capplab-dev


# Create the resource group
az group create --name $resourceGroup --location $location --subscription $subscription --tags "DeployedBy"="Gautier Boder" "DeployedAt"=$(date +%Y-%m-%d:%H:%M:%S) "DeployedFrom"="Azure CLI"

# Create the Log Analytics Workspace
az monitor log-analytics workspace create --resource-group $resourceGroup --workspace-name $logAnalyticsWorkspaceName --location $location
logAnalyticsWorkspaceId=$(az monitor log-analytics workspace show --resource-group $resourceGroup --workspace-name $logAnalyticsWorkspaceName --query customerId --output tsv)
echo $logAnalyticsWorkspaceId
az monitor log-analytics workspace show --resource-group $resourceGroup --workspace-name $logAnalyticsWorkspaceName --query customerId --output tsv
logAnalyticsWorkspaceKey=$(az monitor log-analytics workspace get-shared-keys --resource-group $resourceGroup --workspace-name $logAnalyticsWorkspaceName --query primarySharedKey --output tsv)

# Create the VNet
az network vnet create --name $vnetName --resource-group $resourceGroup --location $location --address-prefixes $vnetAdressPrefix --subnet-name $subnet --subnet-prefix $subnetAdressPrefix
vnetId=$(az network vnet show --name $vnetName --resource-group $resourceGroup --query id --output tsv)
az network vnet subnet create --name $subnet --resource-group $resourceGroup \
    --vnet-name $vnetName --address-prefix $subnetAdressPrefix \
    --delegations "Microsoft.App/environments"
subnetId=$(az network vnet subnet show --name $subnet --resource-group $resourceGroup --vnet-name $vnetName --query id --output tsv)
# Delegate the subnet to Microsoft.App/environments
az network vnet subnet update --name $subnet --resource-group $resourceGroup --vnet-name $vnetName --delegations "Microsoft.App/environments"

# Create the Azure Container Registry
az acr create --name $containerRegistryName --resource-group $resourceGroup --location $location --sku Basic --admin-enabled true
acrId=$(az acr show --name $containerRegistryName --resource-group $resourceGroup --query id --output tsv)
# log activity to the Log Analytics Workspace
az monitor diagnostic-settings create --name $containerRegistryName --resource $acrId \
    --resource-group $resourceGroup --logs '[{"category": "ContainerRegistryRepositoryEvents","enabled": true}]' \
    --workspace $logAnalyticsWorkspaceId

# Add the AcrPull Role to the Managed Identity for the Container Registry
az identity create --name $managedIdentityName --resource-group $resourceGroup --location $location
acrId=$(az acr show --name $containerRegistryName --resource-group $resourceGroup --query id --output tsv)
miId=$(az identity show --name $managedIdentityName --resource-group $resourceGroup --query id --output tsv)
# az role assignment create --assignee $miId --role acrpull --scope $acrId

# Create the Container App Service Environment
az containerapp env create \
    --name $caeName --resource-group $resourceGroup --location $location \
    --logs-destination log-analytics --logs-workspace-id $logAnalyticsWorkspaceId \
    --logs-workspace-key $logAnalyticsWorkspaceKey \
    -s $subnetId
caeId=$(az containerapp env show --name $caeName --resource-group $resourceGroup --query id --output tsv)