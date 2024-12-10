# Deployment

# 1. Deploy the RG

```shell
az deployment sub create --name 
```

# 2. Deploy the infra

```shell
az deployment group create -g $rg --template-file ./infra.main.bicep --parameters ./infra.main-local.bicepparam
```

# 3. Deploy the application

```shell
az deployment group create -g $rg --template-file app.bicep --parameters ./app-local.bicepparam --parameters containerImageTag=XX.XX
```

# Parameters

files named `{}-template.bicepparam.txt` contain the sample parameter to use when running the associated BICEP templates files. To configure those parameter for the environment
copy the _template_ file and name it accordingly, `{}-local.bicepparam`, doing so it will be ignored by git (see `.gitignore` file).

