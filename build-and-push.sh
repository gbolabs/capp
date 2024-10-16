#!/bin/bash

# sample call build-and-push.sh --acr acrcapplabgbodev02 --tag 1.13 --containers web,api,ingress,azcli,carbone,all

# Parse the command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --acr)
        acr="$2"
        shift
        shift
        ;;
        --tag)
        tag="$2"
        shift
        shift
        ;;
        --containers)
        containers="$2"
        shift
        shift
        ;;
        *)
        shift
        ;;
    esac
done

# dump the values
echo "acr: $acr"
echo "tag: $tag"
echo "containers: $containers"

# Set the default values if not provided
if [ -z "$acr" ]; then
    acr=acrcapplabgbodev02
fi
if [ -z "$tag" ]; then
    tag=1.13
fi
if [ -z "$containers" ]; then
    containers=all
fi

# append the acr suffix if it is not already there
if [[ $acr != *".azurecr.io" ]]; then
    acr=$acr.azurecr.io
fi

imagePrefix=$acr/capplab

# authenticate to the Azure Container Registry
az acr login --name $acr


# Build the web
if [[ $containers == *"web"* ]] || [[ $containers == *"all"* ]]; then
    echo "Building the web"
    echo "================"
    docker build -t $imagePrefix/web:$tag -t $imagePrefix/web:latest  -f ./src/web/btweb/Dockerfile ./src/web/btweb
    docker push $imagePrefix/web:$tag
    docker push $imagePrefix/web:latest
else
    echo "Skipping the web"
    echo "================"
    docker tag $imagePrefix/web:latest $imagePrefix/web:$tag
    docker push $imagePrefix/web:$tag
fi


# Build the api
if [[ $containers == *"api"* ]] || [[ $containers == *"all"* ]]; then
    echo "Building the api"
    echo "================"
    docker build -t $imagePrefix/api:$tag -t $imagePrefix/api:latest -f ./src/api/api/Dockerfile ./src/api/api
    docker push $imagePrefix/api:$tag
    docker push $imagePrefix/api:latest
else
    echo "Skipping the api"
    echo "================"
    docker tag $imagePrefix/api:latest $imagePrefix/api:$tag
    docker push $imagePrefix/api:$tag
fi

# Build the ingress
if [[ $containers == *"ingress"* ]] || [[ $containers == *"all"* ]]; then
    echo "Building the ingress"
    echo "================"
    docker build -t $imagePrefix/ingress:$tag -t $imagePrefix/ingress:latest -f ./src/ingress/Dockerfile ./src/ingress
    docker push $imagePrefix/ingress:$tag
    docker push $imagePrefix/ingress:latest
else
    echo "Skipping the ingress"
    echo "================"
    docker tag $imagePrefix/ingress:latest $imagePrefix/ingress:$tag
    docker push $imagePrefix/ingress:$tag
fi

# Build the azcli
if [[ $containers == *"azcli"* ]] || [[ $containers == *"all"* ]]; then
    echo "Building the azcli"
    echo "================"
    docker build -t $imagePrefix/azcli:$tag -t $imagePrefix/azcli:latest -f ./src/azcli/Dockerfile ./src/azcli
    docker push $imagePrefix/azcli:$tag
    docker push $imagePrefix/azcli:latest
else
    echo "Skipping the azcli"
    echo "================"
    docker tag $imagePrefix/azcli:latest $imagePrefix/azcli:$tag
    docker push $imagePrefix/azcli:$tag
fi

# Build the carbone
if [[ $containers == *"carbone"* ]] || [[ $containers == *"all"* ]]; then
    echo "Building the carbone using az acr build to avoid transferring 2GB of data"
    echo "================"
    az acr build --registry $acr --image $imagePrefix/carbone:latest -f ./src/carbone/Dockerfile ./src/carbone
fi