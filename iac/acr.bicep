param location string = resourceGroup().location
@secure()
param pushUserId string
param remoteIp string
param env string = 'dev'

var dashedNameSuffix = 'capplab-${env}-01'
var blockNameSuffix = 'capplabgbo${env}01'
var deployModulePattern = 'acr.module-{0}'

var acrpeVnetAddressPrefix = '10.0.100.0/24'
var acrpeSubnetAddressPrefix = '10.0.100.0/27'
var acrpeSubnetName = 'acrpe-subnet'

// Private DNS Zone for ACR
module privateDnsZoneAcr 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  name: format(deployModulePattern, 'private-dns-zone-acr')
  params: {
    name: 'privatelink.azurecr.io'
    location: location
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetAcr.outputs.resourceId
        location: location
        name: 'vnet-link'
      }
    ]
  }
}

// Virtual Network for ACR
var vnetAcrName = format('vnet-cmn-acr-${dashedNameSuffix}')
module vnetAcr 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, vnetAcrName)
  params: {
    name: vnetAcrName
    location: location
    addressPrefixes: [
      acrpeVnetAddressPrefix
    ]
    subnets: [
      {
        name: acrpeSubnetName
        addressPrefix: acrpeSubnetAddressPrefix
      }
    ]
  }
}


var containerRegistryName = format('acr${blockNameSuffix}')
module containerRegistry 'br/public:avm/res/container-registry/registry:0.5.1' = {
  name: format(deployModulePattern, containerRegistryName)
  params: {
    name: containerRegistryName
    location: location
    acrSku: 'Premium'
    acrAdminUserEnabled:false
    anonymousPullEnabled:false
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    privateEndpoints: [
      {
        name: format('pep-${containerRegistryName}')
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: privateDnsZoneAcrName
              privateDnsZoneResourceId: privateDnsZoneAcr.outputs.resourceId
            }
          ]
        }
        subnetResourceId: pepVNet.outputs.subnetResourceIds[0]
      }
    ]
    exportPolicyStatus:	'enabled'
    publicNetworkAccess: 'Enabled'
    networkRuleSetDefaultAction: 'Deny'
    networkRuleBypassOptions: 'None'
    networkRuleSetIpRules:[
      {
        action: 'Allow'
        value: remoteIp
      }
    ]
    roleAssignments: [
      {
        principalType: 'ServicePrincipal'
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'AcrPull'
      }
      {
        principalType: 'User'
        principalId: pushUserId
        roleDefinitionIdOrName: 'AcrPush'
      }
    ]
  }
}
