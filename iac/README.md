# Deployment

```shell
az deployment group create -g $rg --name capp-lab-infra --template-file infra.main.bicep --parameters infra.main.bicepparam
```