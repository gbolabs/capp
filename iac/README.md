# Deployment

Doesn't work
```shell
az deployment sub create --template-file resourcegroup.bicep -l francecentral --name gbo-capp-lab_rg
```

```shell
az deployment group create -g $rg --name capp-lab-infra --template-file infra.main.bicep --parameters infra.main.bicepparam
```