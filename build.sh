acr=acrgbocaplab.azurecr.io
imagePrefix=acrgbocaplab.azurecr.io/capplab
tag=1.4

# authenticate to the Azure Container Registry
az acr login --name $acr

# Build the web
echo "Building the web"
echo "================"
docker build -t $imagePrefix/web:$tag -t $imagePrefix/web:latest  -f ./src/web/btweb/Dockerfile ./src/web/btweb
docker push $imagePrefix/web:$tag
docker push $imagePrefix/web:latest

# Build the api
echo "Building the api"
echo "================"
docker build -t $imagePrefix/api:$tag -t $imagePrefix/api:latest -f ./src/api/api/Dockerfile ./src/api/api
docker push $imagePrefix/api:$tag
docker push $imagePrefix/api:latest

# Build the ingress
echo "Building the ingress"
echo "================"
docker build -t $imagePrefix/ingress:$tag -t $imagePrefix/ingress:latest -f ./src/ingress/Dockerfile ./src/ingress
docker push $imagePrefix/ingress:$tag
docker push $imagePrefix/ingress:latest

# Build the carbone
echo "Building the carbone using az acr build to avoid transferring 2GB of data"
echo "================"
az acr build --registry $acr --image $imagePrefix/carbone:$tag -f ./src/carbone/Dockerfile ./src/carbone