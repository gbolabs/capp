# Deployment

```shell
az deployment group create -g $rg --name capp-lab-infra --template-file infra.main.bicep --parameters infra.main.bicepparam
```

# Parameters

files named `{}-template.bicepparam.txt` contain the sample parameter to use when running the associated BICEP templates files. To configure those parameter for the environment
copy the _template_ file and name it accordingly, `{}-local.bicepparam`, doing so it will be ignored by git (see `.gitignore` file).