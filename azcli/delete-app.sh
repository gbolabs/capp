
acr=acrgbocaplab.azurecr.io
imagePrefix=acrgbocaplab.azurecr.io/capplab
tag=1.4

location=switzerlandnorth
resourceGroup=rg-capplab-dev

vnetAdressPrefix=192.168.0.0/16
subnetAdressPrefix=192.168.0.0/24
vnetName=vnet-capplab-dev
subnet=cae

containerRegistryName=acrgbocaplab
managedIdentityName=mi-capplab-dev
miId=$(az identity show --name $managedIdentityName --resource-group $resourceGroup --query id --output tsv)

caeName=cae-capplab-dev

capIngressName=cap-ingress-capplab-dev
capApiName=cap-api-capplab-dev
capWebName=cap-web-capplab-dev


# delete the container app api
echo "Deleting the container app api ($capApiName)"
az containerapp delete --name $capApiName --resource-group $resourceGroup --yes

# delete the container app web
echo "Deleting the container app web ($capWebName)"
az containerapp delete --name $capWebName --resource-group $resourceGroup --yes

# delete the container app ingress
echo "Deleting the container app ingress ($capIngressName)"
az containerapp delete --name $capIngressName --resource-group $resourceGroup --yes