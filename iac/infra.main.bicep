param location string = resourceGroup().location
param env string = 'dev'
param dashedNameSuffix string = 'capplab-${env}-01'
param blockNameSuffix string = 'capplabgbo${env}01'
param remoteIp string
param pushUserId string
param budgetAmount int
param budgetNotificationEmail string


var deployModulePattern = 'infra.main-module-{0}'
var caeVnetAddressPrefix = '192.168.0.0/20'
var caeSubnetAddressPrefix = '192.168.0.0/23'
var caeSubnetName = 'cae-subnet'

var pepVnetAddressPrefix = '192.168.96.0/20'
var pepSubnetAddressPrefix = '192.168.96.0/27'
var pepSubnetName = 'pep-subnet'

var nonRegionalLocation = 'global'

// budget
var budgetName = format('budget-${dashedNameSuffix}')
module budget 'br/public:avm/res/consumption/budget:0.3.5' = {
  name: format(deployModulePattern, budgetName)
  scope: subscription(subscription().subscriptionId)
  params: {
    amount: budgetAmount
    category: 'Cost'
    name: budgetName
    resourceGroupFilter: [
      resourceGroup().name
    ]
    thresholdType: 'Forecasted'
    contactEmails: [
      budgetNotificationEmail
    ]
  }
}

// Deploy log analytics workspace
var logWaName = format('logwa-${dashedNameSuffix}')
module workspace 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: format(deployModulePattern, 'logwa-${dashedNameSuffix}')
  params: {
    // Required parameters
    name: logWaName
    // Non-required parameters
    location: location
  }
}
var appiName = format('appi-${blockNameSuffix}')
module appi 'br/public:avm/res/insights/component:0.4.1' = {
  name: format(deployModulePattern, appiName)
  params: {
    // Required parameters
    name: appiName
    // Non-required parameters
    location: location
    applicationType: 'web'
    workspaceResourceId: workspace.outputs.resourceId
    samplingPercentage: 100
  }
}

var storageAccountName = format('st${blockNameSuffix}')
module storageAccount 'br/public:avm/res/storage/storage-account:0.13.2' = {
  name: format(deployModulePattern, storageAccountName)
  params: {
    // Required parameters
    name: storageAccountName
    // Non-required parameters
    location: location
    accessTier: 'Hot'
    skuName: 'Standard_LRS'
  }
}

// Virtual network structure
module caeVNet 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, 'vnet-cae-${dashedNameSuffix}')
  params: {
    // Required parameters
    addressPrefixes: [
      caeVnetAddressPrefix
    ]
    name: format('vnet-cae-${dashedNameSuffix}')
    // Non-required parameters
    location: location
    subnets: [
      {
        name: caeSubnetName
        addressPrefix: caeSubnetAddressPrefix
        networkSecurityGroupResourceId: nsg.outputs.resourceId
      }
    ]
  }
}
module pepVNet 'br/public:avm/res/network/virtual-network:0.4.0' = {
  name: format(deployModulePattern, 'vnet-pep-${dashedNameSuffix}')
  params: {
    // Required parameters
    addressPrefixes: [
      pepVnetAddressPrefix
    ]
    name: format('vnet-pep-${dashedNameSuffix}')
    // Non-required parameters
    location: location
    subnets: [
      {
        name: pepSubnetName
        addressPrefix: pepSubnetAddressPrefix
      }
    ]
    peerings: [
      {
        name: 'pep-cae-peer'
        remoteVirtualNetworkResourceId: caeVNet.outputs.resourceId
        allowVirtualNetworkAccess: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'cae-pep-peer'
      }
    ]
  }
}

// Private DNS zone
var privateDnsZoneAcrName = 'privatelink${environment().suffixes.acrLoginServer}'
var sqlServerPrivateDnsZone = 'privatelink${environment().suffixes.sqlServerHostname}'
module privateDnsZoneAcr 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  name: format(deployModulePattern, 'dns-${privateDnsZoneAcrName}')
  params: {
    name: privateDnsZoneAcrName
    location: nonRegionalLocation
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: caeVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'cae-vnet-link'
      }
      {
        virtualNetworkResourceId: pepVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'pep-vnet-link'
      }
    ]
  }
}
module privateDnsZoneSql 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  name: format(deployModulePattern, 'dns-${sqlServerPrivateDnsZone}')
  params: {
    name: sqlServerPrivateDnsZone
    location: nonRegionalLocation
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: caeVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'cae-vnet-link'
      }
      {
        virtualNetworkResourceId: pepVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'pep-vnet-link'
      }
    ]
  }
}

// Network security group
var nsgName = format('nsg-${dashedNameSuffix}')
module nsg 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: format(deployModulePattern, nsgName)
  params: {
    // Required parameters
    name: nsgName
    location: location
    // Non-required parameters
    securityRules: [
      {
        name: 'allow-container-registries'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 200
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureContainerRegistry'
          destinationPortRange: '443'
        }
      }
    ]
    diagnosticSettings:[
      {
        name: 'nsg-diag'
        workspaceResourceId: workspace.outputs.resourceId
        logCategoriesAndGroups:[
          {
            category: 'NetworkSecurityGroupEvent'
            enabled: true
          }
        ]
      }
    ]
  }
}

var cappIdName = format('id-capp-${dashedNameSuffix}')
module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: format(deployModulePattern, cappIdName)
  params: {
    // Required parameters
    name: cappIdName
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

// var sqlSrvName = format('sqlsrv-${dashedNameSuffix}')
// var dbName = format('db-${dashedNameSuffix}')
// module sqlSrvRes 'br/public:avm/res/sql/server:0.8.0' = {
//   name: format(deployModulePattern, sqlSrvName)
//   params: {
//     name: sqlSrvName
//     location: location
//     publicNetworkAccess: 'Disabled'
//     administrators:{
//       azureADOnlyAdminLogin: true
//       azureADOnlyAdminLoginPrincipalId: userAssignedIdentity.outputs.principalId
//     }
//     databases: [
//       {
//         name: dbName
//         collation: 'SQL_Latin1_General_CP1_CI_AS'
//       }
//     ]
//     privateEndpoints: [
//       {
//         name: format('pep-${sqlSrvName}')
//         privateDnsZoneGroup: {
//           privateDnsZoneGroupConfigs: [
//             {
//               name: sqlServerPrivateDnsZone
//               privateDnsZoneResourceId: privateDnsZoneSql.outputs.resourceId
//             }
//           ]
//         }
//         subnetResourceId: pepVNet.outputs.resourceId
//       }
//     ]
//   }
// }

var caeName = format('cae-${dashedNameSuffix}')
module managedEnvironment 'br/public:avm/res/app/managed-environment:0.8.0' = {
  name: format(deployModulePattern, caeName)
  params: {
    // Required parameters
    logAnalyticsWorkspaceResourceId: workspace.outputs.resourceId
    name: caeName
    // Non-required parameters
    location: location
    appInsightsConnectionString: appi.outputs.connectionString
    infrastructureSubnetId: caeVNet.outputs.subnetResourceIds[0]
    infrastructureResourceGroupName: resourceGroup().name
    enableTelemetry: true
    logsDestination: 'log-analytics'
  }
}

// outputs
output caeName string = caeName
output acrName string = containerRegistryName
output uaidName string = userAssignedIdentity.outputs.name
output acrLoginServer string = containerRegistry.outputs.loginServer
