
acr=acrgbocaplab.azurecr.io
imagePrefix=acrgbocaplab.azurecr.io/capplab
tag=1.4

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
capCarboneName=cap-carbone-gbo-capplab-dev

# deploy the container app carbone
az containerapp create --name $capCarboneName \
    --resource-group $resourceGroup \
    --image $imagePrefix/carbone:$tag \
    --registry-server $acr \
    --registry-identity $miId \
    --ingress internal --target-port 4000 \
    --environment $caeName

carboneHostname=$(az containerapp show --name $capCarboneName --resource-group $resourceGroup --query "properties.configuration.ingress.fqdn" --output tsv)

# deploy the container app api 
az containerapp create --name $capApiName \
    --resource-group $resourceGroup \
    --registry-server $acr \
    --registry-identity $miId \
    --image $imagePrefix/api:$tag \
    --ingress internal --target-port 8080 \
    --environment $caeName

apiHostname=$(az containerapp show --name $capApiName --resource-group $resourceGroup --query "properties.configuration.ingress.fqdn" --output tsv)

# deploy the container app web
az containerapp create --name $capWebName \
    --resource-group $resourceGroup \
    --image $imagePrefix/web:$tag \
    --registry-server $acr \
    --registry-identity $miId \
    --ingress internal --target-port 80 \
    --environment $caeName

webHostname=$(az containerapp show --name $capWebName --resource-group $resourceGroup --query "properties.configuration.ingress.fqdn" --output tsv)
echo "Web Hostname: $webHostname"

# deploy the container app ingress
az containerapp create --name $capIngressName \
    --resource-group $resourceGroup \
    --image $imagePrefix/ingress:$tag \
    --registry-server $acr \
    --registry-identity $miId \
    --ingress external --target-port 80 \
    --environment $caeName \
    --env-vars DEBUG=1 \
    --env-vars CAPP_API_HOST=$apiHostname \
    --env-vars CAPP_API_PORT=443 \
    --env-vars CAPP_API_SCHEME=https \
    --env-vars CAPP_WEB_HOST=$webHostname \
    --env-vars CAPP_WEB_PORT=443 \
    --env-vars CAPP_WEB_SCHEME=https \
    --env-vars CAPP_CARBONE_HOST=$carboneHostname \
    --env-vars CAPP_CARBONE_PORT=443 \
    --env-vars CAPP_CARBONE_SCHEME=https
ingressHostname=$(az containerapp show --name $capIngressName --resource-group $resourceGroup --query "properties.configuration.ingress.fqdn" --output tsv)
echo "Ingress Hostname: $ingressHostname"