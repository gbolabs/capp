#!/bin/bash
location=switzerlandnorth
resourceGroup=rg-capplab-dev
subscription=199fc2c4-a57c-4049-afbe-e1831f4b2f6e

vnetAdressPrefix=192.168.0.0/16
subnetAdressPrefix=192.168.0.0/24
subnetPepAdressPrefix=192.168.1.0/24
vnetName=vnet-capplab-dev
subnet=cae
pepSubnet=peps
networkSecurityGroupName=nsg-$pepSubnet-capplab-dev

containerRegistryName=acrgbocaplab
managedIdentityName=mi-capplab-dev

caeName=cae-capplab-dev

capIngressName=cap-ingress-capplab-dev
capApiName=cap-api-capplab-dev
capWebName=cap-web-capplab-dev

logAnalyticsWorkspaceName=law-capplab-dev

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {deny|allow}"
    exit 1
fi

# Assign the first argument to the mode variable
mode=$1

# Check if the mode is either 'deny' or 'allow'
if [ "$mode" != "deny" ] && [ "$mode" != "allow" ]; then
    echo "Invalid mode. Use 'deny' or 'allow'."
    exit 1
fi

# echo delete rule 100 from nsg
echo "Deleting the existing rule id 100 from the network security group"
denyRuleName="DenyHttpsToAcr"
az network nsg rule delete \
    --name $denyRuleName \
    --nsg-name $networkSecurityGroupName \
    --resource-group $resourceGroup \
    1> /dev/null

# Perform actions based on the mode
if [ "$mode" == "deny" ]; then
    # Deny the https trafic to the acr private endpoint
    echo "Denying the https trafic to the acr private endpoint"
    az network nsg rule create \
        --name $denyRuleName \
        --nsg-name $networkSecurityGroupName \
        --resource-group $resourceGroup \
        --priority 100 \
        --source-address-prefixes VirtualNetwork \
        --destination-address-prefixes AzureContainerRegistry \
        --destination-port-ranges 443 \
        --access Deny \
        --direction Inbound \
        --protocol Tcp \
        1> /dev/null
elif [ "$mode" == "allow" ]; then
    # Allow the https trafic to the acr private endpoint
    echo "Allowing the https trafic to the acr private endpoint"
    echo "Allowing is already done by the default rules, ID 200"
fi