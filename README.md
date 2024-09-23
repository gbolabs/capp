# Objective

Simulate a container app-based deployment of ingres (nginx) routing trafic to a web (angular on nginx) and api (dotnet) containers.

This allow to validate the concepts and do some testing in an easier environment that an real-deployment.

# Implementation

Only the nginx container app is accessible from outside the container app environments. It proxy_pass the trafic to the web and api container over the private vnet used as infrastructure.

The container images are pulled from a container registry, only accesible via private endpoint, authenticated using user-assigned managed identity.

# Setup

- Install a WSL distro (e.g. Ubuntu)
- Install Dcoker
- Install AzureCli
- Install dotnet
- Install NodeJs

# Run 

You've to clone the repo on a linux-based system (e.g. WSL or MacOS) if you want to use the bash scripts.

## locally

Execute at the root of the repo
`docker compose up -d --build`

## on Azure

First, within the bash shell, login against Azure using
`az login -t {tenant}`

Then, in sequence,

### Using BICEP Template
The BICEP templates are located within `iac/`-directory where the `infra.main.bicep` and `infra.main.bicepparam` files create the initial infrastructure.

#### Infrastructure

```bash
az login -t {tenant-name | tenant-id}
az deployment group create -g {rg} --name capp-infra --template-file infra.main.bicep --parameters infra.main.bicepparam
```

#### App
```bash
az login -t {tenant-name | tenant-id}
az deployment group create -g {rg} --name capp-apps --template-file app.bicep --parameters app.bicepparam
```


### Using Azure CLI
This variant doesn't support, yet, the database dbupdate sidecar. Scripts are located within the `azcli` directory.

- Deploy the Azure Infrastructure (starts from resource groups to the container app environment)
  `./deploy-infra.sh.azcli`
- Build the three containers image and pushes them to the ACR
    `./build.sh`
- Deploy the container app instances by pulling the images from the container registry
    `./deploy-app.sh`

You can test the app on the returned url for ingress.

#### Enable NSG

You can block the communication between the container apps and the container registry by using the

`./setup-nsg-acr.sh {allow|deny}` script