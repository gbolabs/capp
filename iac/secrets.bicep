param vaultName string
param secrets array = [
  {
    name: 'test002'
    value: guid('test002')
  }
]

resource secretsResource 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = [for (secret, index) in secrets: {
   name: '${vaultName}/${secret.name}'
    properties: {
      value: secret.value
    }
}]
