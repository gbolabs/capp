location=switzerlandnorth
resourceGroup=rg-capplab-dev

vnetAdressPrefix=192.168.0.0/16
subnetAdressPrefix=192.168.0.0/24
vnetPepAdressPrefix=10.0.1.0/16
subnetPepAdressPrefix=10.0.1.0/24
vnetName=vnet-cae-capplab-dev
vnetPepName=vnet-pep-capplab-dev
subnet=cae
pepSubnet=peps
networkSecurityGroupName=nsg-$pepSubnet-capplab-dev

containerRegistryName=acrgbocaplab
managedIdentityName=mi-capplab-dev

caeName=cae-capplab-dev

capIngressName=cap-ingress-capplab-dev
capApiName=cap-api-capplab-dev
capWebName=cap-web-capplab-dev
flowLogStorageAccountName=stgbocapplabflowlogsdev

logAnalyticsWorkspaceName=law-capplab-dev

azsqlServerName=sql-capplab-dev
azsqlDbName=db-capplab-dev

# Create the resource group
echo -e "\n\nCreating resource group..."
az group create \
    --name $resourceGroup \
    --location $location \
    --subscription $subscription \
    --tags "DeployedAt"=$(date +%Y-%m-%d:%H:%M:%S) "DeployedFrom"="Azure CLI" \
    1>/dev/null

# Create the Log Analytics Workspace
echo -e "\n\nCreating Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --resource-group $resourceGroup \
    --workspace-name $logAnalyticsWorkspaceName \
    --location $location \
    1>/dev/null

logAnalyticsWorkspaceId=$(az monitor log-analytics workspace show \
    --resource-group $resourceGroup \
    --workspace-name $logAnalyticsWorkspaceName \
    --query id \
    --output tsv)

echo $logAnalyticsWorkspaceId

logAnalyticsWorkspaceCustomerId=$(az monitor log-analytics workspace show \
    --resource-group $resourceGroup \
    --workspace-name $logAnalyticsWorkspaceName \
    --query customerId \
    --output tsv)

logAnalyticsWorkspaceKey=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group $resourceGroup \
    --workspace-name $logAnalyticsWorkspaceName \
    --query primarySharedKey \
    --output tsv)

echo ""

# Create a storage account for the flow logs
echo -e "\n\nCreating storage account for the flow logs..."
az storage account create \
    --name $flowLogStorageAccountName \
    --resource-group $resourceGroup \
    --location $location \
    --sku Standard_LRS \
    1>/dev/null

# Create the VNet
echo -e "\n\nCreating Virtual Network..."
az network vnet create \
    --name $vnetName \
    --resource-group $resourceGroup \
    --location $location \
    --address-prefixes $vnetAdressPrefix \
    --subnet-name $subnet \
    --subnet-prefix $subnetAdressPrefix \
    1>/dev/null

echo ""

vnetId=$(az network vnet show \
    --name $vnetName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)

echo -e "\n\nCreating subnet..."
az network vnet subnet create \
    --name $subnet \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --address-prefix $subnetAdressPrefix \
    --delegations "Microsoft.App/environments" \
    1>/dev/null

echo ""

subnetId=$(az network vnet subnet show \
    --name $subnet \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --query id \
    --output tsv)

echo ""

# Delegate the subnet to Microsoft.App/environments
echo -e "\n\nDelegating subnet to Microsoft.App/environments..."
az network vnet subnet update \
    --name $subnet \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --delegations "Microsoft.App/environments" \
    1>/dev/null

echo ""

# Create the VNet for the private endpoint
echo -e "\n\nCreating Virtual Network for the private endpoint..."
az network vnet create \
    --name $vnetPepName \
    --resource-group $resourceGroup \
    --location $location \
    --address-prefixes $vnetPepAdressPrefix \
    --subnet-name $pepSubnet \
    --subnet-prefix $subnetPepAdressPrefix \
    1>/dev/null

echo ""

# Peer the VNet with the private endpoint VNet
echo -e "\n\nPeering the VNet with the private endpoint VNet..."
az network vnet peering create \
    --name "peering-$vnetName-$vnetPepName" \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --remote-vnet $vnetPepName \
    --allow-vnet-access \
    --allow-forwarded-traffic \
    --allow-gateway-transit \
    --allow-egress \
    --use-remote-gateways \
    1>/dev/null

# Create a network security group for the subnet
echo -e "\n\nCreating network security group for the subnet..."
az network nsg create \
    --name $networkSecurityGroupName \
    --resource-group $resourceGroup \
    --location $location \
    1>/dev/null

echo ""

# Create a network security group rule to allow traffic from the subnet to the Azure Container Registry
echo -e "\n\nCreating network security group rule for Azure Container Registry..."
az network nsg rule create \
    --name "acr" \
    --resource-group $resourceGroup \
    --nsg-name $networkSecurityGroupName \
    --priority 200 \
    --source-address-prefixes VirtualNetwork \
    --destination-address-prefixes AzureContainerRegistry \
    --destination-port-ranges 443 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    1>/dev/null

echo ""

# Associate the network security group with the subnet
echo -e "\n\nAssociating network security group with the subnets..."
az network vnet subnet update \
    --name $pepSubnet \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --network-security-group $networkSecurityGroupName \
    1>/dev/null

az network vnet subnet update \
    --name $subnet \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --network-security-group $networkSecurityGroupName \
    1>/dev/null
echo ""

# Create Nsg Flow Logs
# az network watcher flow-log create --location westus --resource-group MyResourceGroup --name MyFlowLog --nsg MyNetworkSecurityGroupName --storage-account account
echo -e "\n\nCreating Network Security Group Flow Logs..."
az network watcher flow-log create \
    --location $location \
    --resource-group $resourceGroup \
    --name "$networkSecurityGroupName-flowlogs" \
    --nsg $networkSecurityGroupName \
    --enabled true \
    --retention 7 \
    --storage-account $flowLogStorageAccountName \
    1>/dev/null

# Create the Private DNS Zone for the Azure Container Registry private endpoint
echo -e "\n\nCreating Private DNS Zone for Azure Container Registry..."
az network private-dns zone create \
    --name "privatelink.azurecr.io" \
    --resource-group $resourceGroup \
    1>/dev/null

echo ""

# Create the private dns zone for azure sql server
echo -e "\n\nCreating Private DNS Zone for Azure SQL Server..."
az network private-dns zone create \
    --name "privatelink.database.windows.net" \
    --resource-group $resourceGroup \
    1>/dev/null

echo ""

# Create the Private DNS Link for the Azure SQL Server private endpoint
echo -e "\n\nCreating Private DNS Link for Azure SQL Server..."
az network private-dns link vnet create \
    --name "sql" \
    --resource-group $resourceGroup \
    --zone-name "privatelink.database.windows.net" \
    --virtual-network $vnetName \
    --registration-enabled false \
    1>/dev/null

# Create the Private DNS Link for the Azure Container Registry private endpoint
echo -e "\n\nCreating Private DNS Link for Azure Container Registry..."
az network private-dns link vnet create \
    --name "acr" \
    --resource-group $resourceGroup \
    --zone-name "privatelink.azurecr.io" \
    --virtual-network $vnetName \
    --registration-enabled false \
    1>/dev/null

echo ""

# Create the Azure Container Registry
echo -e "\n\nCreating Azure Container Registry..."
az acr create \
    --name $containerRegistryName \
    --resource-group $resourceGroup \
    --location $location \
    --sku Premium \
    --admin-enabled false \
    --allow-trusted-services false \
    --default-action Deny \
    1>/dev/null

# Allow current ip to access the container registry
echo -e "\n\nAllowing current IP to access the Azure Container Registry..."
currentIp=$(curl -s ifconfig.me)
az acr network-rule add \
    --name $containerRegistryName \
    --resource-group $resourceGroup \
    --ip-address $currentIp \
    1>/dev/null

echo ""

acrId=$(az acr show \
    --name $containerRegistryName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)

echo ""

# Create the private endpoint for the Azure Container Registry
echo -e "\n\nCreating private endpoint for Azure Container Registry..."
az network private-endpoint create \
    --name "pep-$containerRegistryName-capplab-dev" \
    --nic-name "nic-pep-$containerRegistryName-capplab-dev" \
    --connection-name "acr" \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --subnet $pepSubnet \
    --private-connection-resource-id $acrId \
    --group-id registry \
    1>/dev/null

echo ""

# Log activity to the Log Analytics Workspace
echo -e "\n\nLogging activity to Log Analytics Workspace..."
az monitor diagnostic-settings create \
    --name $containerRegistryName \
    --resource $acrId \
    --resource-group $resourceGroup \
    --logs '[{"category": "ContainerRegistryRepositoryEvents","enabled": true}]' \
    --workspace $logAnalyticsWorkspaceId \
    1>/dev/null

echo ""

# Add the AcrPull Role to the Managed Identity for the Container Registry
echo -e "\n\nCreating Managed Identity and assigning AcrPull Role..."
az identity create \
    --name $managedIdentityName \
    --resource-group $resourceGroup \
    --location $location \
    1>/dev/null

echo ""

acrId=$(az acr show \
    --name $containerRegistryName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)

miId=$(az identity show \
    --name $managedIdentityName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)

miIdObjId=$(az identity show \
    --name $managedIdentityName \
    --resource-group $resourceGroup \
    --query principalId \
    --output tsv)

echo ""

az role assignment create \
    --assignee-object-id $miIdObjId \
    --assignee-principal-type ServicePrincipal \
    --role acrpull \
    --scope $acrId \
    1>/dev/null

echo ""

# Create the Azure SQL Server with AAD Authentication only and admin so to the managed identity
echo -e "\n\nCreating Azure SQL Server... "
az sql server create \
    --name $azsqlServerName \
    --resource-group $resourceGroup \
    --location $location \
    --enable-ad-only-auth \
    --external-admin-principal-type ServicePrincipal \
    --external-admin-name $managedIdentityName \
    --external-admin-sid $miIdObjId \
    1>/dev/null

azsqlServerId=$(az sql server show \
    --name $azsqlServerName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)

echo ""

# Add the private endpoint to the Azure SQL Server
echo -e "\n\nAdding private endpoint to Azure SQL Server..."
az network private-endpoint create \
    --name "pep-$azsqlServerName-capplab-dev" \
    --nic-name "nic-pep-$azsqlServerName-capplab-dev" \
    --connection-name "sql" \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --subnet $pepSubnet \
    --private-connection-resource-id $azsqlServerId \
    --group-id sqlServer \
    1>/dev/null

echo ""

# Create the Azure SQL Database (BASIC TIER)
echo -e "\n\nCreating Azure SQL Database..."
az sql db create \
    --name $azsqlDbName \
    --resource-group $resourceGroup \
    --server $azsqlServerName \
    --tier Basic \
    --collation French_CI_AS \
    1>/dev/null

# Create the Container App Service Environment
echo -e "\n\nCreating Container App Service Environment..."
az containerapp env create \
    --name $caeName \
    --resource-group $resourceGroup \
    --location $location \
    --logs-destination log-analytics \
    --logs-workspace-id $logAnalyticsWorkspaceCustomerId \
    --logs-workspace-key $logAnalyticsWorkspaceKey \
    -s $subnetId \
    1>/dev/null

echo ""

caeId=$(az containerapp env show \
    --name $caeName \
    --resource-group $resourceGroup \
    --query id \
    --output tsv)