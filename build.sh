acr=acrgbocaplab.azurecr.io
imagePrefix=acrgbocaplab.azurecr.io/capplab
tag=1.4.11

# authenticate to the Azure Container Registry
az acr login --name $acr

# Build the web
docker build -t $imagePrefix/web:$tag -t $imagePrefix/web:latest  -f ./web/btweb/Dockerfile ./web/btweb
docker push $imagePrefix/web:$tag
docker push $imagePrefix/web:latest

# Build the api
docker build -t $imagePrefix/api:$tag -t $imagePrefix/api:latest -f ./api/Dockerfile ./api
docker push $imagePrefix/api:$tag
docker push $imagePrefix/api:latest

# Build the ingress
docker build -t $imagePrefix/ingress:$tag -t $imagePrefix/ingress:latest -f ./ingress/Dockerfile ./ingress
docker push $imagePrefix/ingress:$tag
docker push $imagePrefix/ingress:latest