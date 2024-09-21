param location string = resourceGroup().location
param env string = 'dev'
param dashedNameSuffix string = 'capplab-gbo-${env}-01'
param blockNameSuffix string = 'capplabgbo${env}01'

param caeEnvName string
param acrName string
param uaidName string
param containerImageRepository string
param containerImageTag string

var deployModulePattern = 'infra.main-module-{0}'
var apiCappName = format('cap-api-${dashedNameSuffix}')
var webCappName = format('cap-web-${dashedNameSuffix}')
var carboneCappName = format('cap-carbone-${dashedNameSuffix}')
var ingressCappName = format('ingress-${dashedNameSuffix}')


resource cae 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: caeEnvName
}
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}
resource uaid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: uaidName
}

module cappApi 'br/public:avm/res/app/container-app:0.9.0'={
  name: format(deployModulePattern, apiCappName)
  params:{
    name: apiCappName
    location: location
    environmentResourceId: cae.id
    managedIdentities:{
      userAssignedResourceIds:[
        uaid.id
      ]
    }
    registries: [
      {
        registry: acr.id
      }
    ]
    containers:[
      {
        image: '$(containerImageRepository)/api:$(containerImageTag)'
        name: 'api'
        resources:{
          requests:{
            cpu: '0.1'
            memory: '128Mi'
          }
          limits:{
            cpu: '0.5'
            memory: '256Mi'
          }
        }
      }
    ]
  }
}
