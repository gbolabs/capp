
acr=acrgbocaplab.azurecr.io
imagePrefix=acrgbocaplab.azurecr.io/capplab
tag=1.4.11

location=switzerlandnorth
resourceGroup=rg-gbo-capplab-dev
subscription=199fc2c4-a57c-4049-afbe-e1831f4b2f6e

vnetAdressPrefix=192.168.0.0/16
subnetAdressPrefix=192.168.0.0/24
vnetName=vnet-gbo-capplab-dev
subnet=cae

containerRegistryName=acrgbocaplab
managedIdentityName=mi-gbo-capplab-dev
miId=$(az identity show --name $managedIdentityName --resource-group $resourceGroup --query id --output tsv)

caeName=cae-gbo-capplab-dev

capIngressName=cap-ingress-gbo-capplab-dev
capApiName=cap-api-gbo-capplab-dev
capWebName=cap-web-gbo-capplab-dev

# deploy the container app api 
az containerapp create --name $capApiName \
    --resource-group $resourceGroup \
    --registry-server $acr \
    --registry-identity $miId \
    --image $imagePrefix/api:$tag \
    --ingress internal --target-port 8080 \
    --environment $caeName

apiHostname=$(az containerapp show --name $capApiName --resource-group $resourceGroup --query fqdn --output tsv)
echo "API Hostname: $apiHostname"

# deploy the container app web
az containerapp create --name $capWebName \
    --resource-group $resourceGroup \
    --image $imagePrefix/web:$tag \
    --registry-server $acr \
    --registry-identity $miId \
    --ingress internal --target-port 80 \
    --environment $caeName

webHostname=$(az containerapp show --name $capWebName --resource-group $resourceGroup --query fqdn --output tsv)
echo "Web Hostname: $webHostname"

# deploy the container app ingress
az containerapp create --name $capIngressName \
    --resource-group $resourceGroup \
    --image $imagePrefix/ingress:$tag \
    --registry-server $acr \
    --registry-identity $miId \
    --ingress external --target-port 80 \
    --environment $caeName