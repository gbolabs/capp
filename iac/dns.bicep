param location string
param env string = 'dev'
param commonSubscription string
param commonResourceGroup string
param appSubscription string
param appResourceGroup string

param vnetAcrName string
param vnetAppName string
param vnetVmsName string

var dashedNameSuffix = 'capplab-${env}-01'
var deployModulePattern = 'acr.module-{0}'

targetScope = 'managementGroup'

// Existing resources
resource vnetAcr 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetAcrName
  scope: resourceGroup(commonResourceGroup, commonSubscription)
}

resource vnetApp 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetAppName
  scope: resourceGroup(appResourceGroup, appSubscription)
}

resource vnetVms 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetVmsName
  scope: resourceGroup(appResourceGroup, appSubscription)
}

