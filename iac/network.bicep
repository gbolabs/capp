param location string
param env string = 'dev'
param commonSubscription string
param commonResourceGroup string
param appSubscription string
param appResourceGroup string


var vnetAcrAddressPrefix = '10.0.0.0/24'
var subnetAcrPeAddressPrefix = '10.0.0.0/27'
var subnetAcrPeName = 'acrpe-subnet'

var vnetAppAddressPrefix = '10.1.0.0/24'
var subnetCaeAddressPrefix = '10.1.0.0/27'
var subnetCaeName = 'cae-subnet'
var subnetPeAddressPrefix = '10.1.0.32/27'
var subnetPeName = 'pe-subnet'

var vnetVmsAddressPrefix = '10.2.0.0/24'
var subnetClientAddressPrefix = '10.2.0.0/27'
var subnetClientName = 'client-subnet'
var subnetDevOpsAgentAddressPrefix = '10.2.0.32/27'
var subnetDevOpsAgentName = 'devops-agent-subnet'


var dashedNameSuffix = 'capplab-${env}-01'
var deployModulePattern = 'acr.module-{0}'

targetScope = 'managementGroup'

// Create a virtual network for the Azure Container Registry
var vnetAcrName = format('vnet-cmn-acr-${dashedNameSuffix}')
module vnetAcr 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, vnetAcrName)
  scope: resourceGroup(commonSubscription, commonResourceGroup)
  params: {
    name: vnetAcrName
    location: location
    addressPrefixes: [
      vnetAcrAddressPrefix
    ]
    subnets: [
      {
        name: subnetAcrPeName
        addressPrefix: subnetAcrPeAddressPrefix
      }
    ]
  }
}

// Create a virtual network for the application
var vnetAppName = format('vnet-cmn-app-${dashedNameSuffix}')
module vnetApp 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, vnetAppName)
  scope: resourceGroup(appSubscription, appResourceGroup)
  params: {
    name: vnetAppName
    location: location
    addressPrefixes: [
      vnetAppAddressPrefix
    ]
    subnets: [
      {
        name: subnetCaeName
        addressPrefix: subnetCaeAddressPrefix
      }
      {
        name: subnetPeName
        addressPrefix: subnetPeAddressPrefix
      }
    ]
    peerings: [
      {
        name: 'cae-acr-peer'
        remoteVirtualNetworkResourceId: vnetAcr.outputs.resourceId
        allowVirtualNetworkAccess: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'acr-cae-peer'
      }
    ]
  }
}

// Create a virtual network for the virtual machines
var vnetVmsName = format('vnet-cmn-vms-${dashedNameSuffix}')
module vnetVms 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, vnetVmsName)
  scope: resourceGroup(appSubscription, appResourceGroup)
  params: {
    name: vnetVmsName
    location: location
    addressPrefixes: [
      vnetVmsAddressPrefix
    ]
    subnets: [
      {
        name: subnetClientName
        addressPrefix: subnetClientAddressPrefix
      }
      {
        name: subnetDevOpsAgentName
        addressPrefix: subnetDevOpsAgentAddressPrefix
      }
    ]
    peerings: [
      {
        name: 'client-cae-peer'
        remoteVirtualNetworkResourceId: vnetApp.outputs.resourceId
        allowVirtualNetworkAccess: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'cae-client-peer'
      }
      {
        name: 'client-acr-peer'
        remoteVirtualNetworkResourceId: vnetAcr.outputs.resourceId
        allowVirtualNetworkAccess: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'acr-client-peer'
      }
    ]
  }
}

output vnetAcrId string = vnetAcr.outputs.resourceId
output vnetAppId string = vnetApp.outputs.resourceId
output vnetVmsId string = vnetVms.outputs.resourceId
output vnetAcrSubnetId string = vnetAcr.outputs.subnetResourceIds[0]
output vnetAppCaeSubnetId string = vnetApp.outputs.subnetResourceIds[0]
output vnetAppPeSubnetId string = vnetApp.outputs.subnetResourceIds[1]
output vnetVmsClientSubnetId string = vnetVms.outputs.subnetResourceIds[0]
output vnetVmsDevOpsAgentSubnetId string = vnetVms.outputs.subnetResourceIds[1]
output vnetAcrName string = vnetAcrName
output vnetAppName string = vnetAppName
output vnetVmsName string = vnetVmsName
output vnetAcrSubnetName string = subnetAcrPeName
output vnetAppCaeSubnetName string = subnetCaeName
output vnetAppPeSubnetName string = subnetPeName
output vnetVmsClientSubnetName string = subnetClientName
output vnetVmsDevOpsAgentSubnetName string = subnetDevOpsAgentName
