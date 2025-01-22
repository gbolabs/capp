param location string = resourceGroup().location
param env string = 'dev'
param resIndex string = '03'
param dashedNameSuffix string = 'capplab-${env}-${resIndex}'
param blockNameSuffix string = 'capplabgbo${env}${resIndex}'
param firewallIpWhitelist array
param pushUserId string
param sqlServerLogin string
@secure()
param sqlServerSecret string
param useEntraOnlySqlAuthentications bool = false

var deployModulePattern = '${deployment().name}-{0}'
var caeVnetAddressPrefix = '192.168.0.0/20'
var caeSubnetAddressPrefix = '192.168.0.0/23'
var caeSubnetName = 'cae-subnet'

var vmSubnetAddressPrefix = '192.168.2.0/24'
var vmSubnetName = 'vm-subnet'

var pepVnetAddressPrefix = '192.168.96.0/20'
var pepSubnetAddressPrefix = '192.168.96.0/27'
var pepSubnetName = 'pep-subnet'

var nonRegionalLocation = 'global'

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
    publicNetworkAccess: 'Enabled'
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    roleAssignments: [
      {
        principalType: 'User'
        principalId: pushUserId
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
      {
        principalType: 'ServicePrincipal'
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        for ip in firewallIpWhitelist: {
          value: ip
          action: 'Allow'
        }
      ]
    }
    privateEndpoints: [
      {
        service: 'blob'
        subnetResourceId: pepVNet.outputs.subnetResourceIds[0]
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: storageAccountPrivateDnsZone
              privateDnsZoneResourceId: privateDnsZoneStorage.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

var fileShareName = format('share-${caeName}')
resource fileShareServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: '${storageAccountName}/default'
  dependsOn: [storageAccount]
}
resource fileShareRes 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileShareServices
  name: fileShareName
  properties: {
    enabledProtocols: 'SMB'
    accessTier: 'Hot'
  }
}

var kvName = format('kv-${dashedNameSuffix}')
module kv 'br/public:avm/res/key-vault/vault:0.10.0' = {
  name: format(deployModulePattern, kvName)
  params: {
    name: kvName
    location: location
    sku: 'standard'
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        for ip in firewallIpWhitelist: {
          value: ip
          action: 'Allow'
        }
      ]
    }
    privateEndpoints: [
      {
        name: format('pep-${kvName}')
        subnetResourceId: pepVNet.outputs.subnetResourceIds[0]
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: kvPrivateDnsZone
              privateDnsZoneResourceId: privateDnsZoneKv.outputs.resourceId
            }
          ]
        }
      }
    ]
    roleAssignments: [
      {
        principalType: 'User'
        principalId: pushUserId
        roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
        // roleDefinitionIdOrName: 'Key Vault Secrets Officer'
      }
      {
        principalType: 'ServicePrincipal'
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
        // roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
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
        // networkSecurityGroupResourceId: nsg.outputs.resourceId
      }
      {
        name: vmSubnetName
        addressPrefix: vmSubnetAddressPrefix
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
        remotePeeringAllowForwardedTraffic: false
        allowForwardedTraffic: false
        remotePeeringName: 'cae-pep-peer'
      }
    ]
  }
}

// Private DNS zone
var privateDnsZoneAcrName = 'privatelink${environment().suffixes.acrLoginServer}'
var sqlServerPrivateDnsZone = 'privatelink${environment().suffixes.sqlServerHostname}'
var kvPrivateDnsZone = 'privatelink${environment().suffixes.keyvaultDns}'
var storageAccountPrivateDnsZone = 'privatelink.${environment().suffixes.storage}'
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
module privateDnsZoneKv 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  name: format(deployModulePattern, 'dns-${kvName}')
  params: {
    name: kvPrivateDnsZone
    location: nonRegionalLocation
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: pepVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'pep-vnet-link'
      }
      { virtualNetworkResourceId: caeVNet.outputs.resourceId, location: nonRegionalLocation, name: 'cae-vnet-link' }
    ]
  }
}
module privateDnsZoneStorage 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  name: format(deployModulePattern, 'dns-${storageAccountName}')
  params: {
    name: storageAccountPrivateDnsZone
    location: nonRegionalLocation
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: pepVNet.outputs.resourceId
        location: nonRegionalLocation
        name: 'pep-vnet-link'
      }
      { virtualNetworkResourceId: caeVNet.outputs.resourceId, location: nonRegionalLocation, name: 'cae-vnet-link' }
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
var sqlAdminMid = format('id-sqladmin-${dashedNameSuffix}')
module sqlAdminMidRes 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: format(deployModulePattern, sqlAdminMid)
  params: {
    // Required parameters
    name: sqlAdminMid
  }
}

var containerRegistryName = format('acr${blockNameSuffix}')
module containerRegistry 'br/public:avm/res/container-registry/registry:0.5.1' = {
  name: format(deployModulePattern, containerRegistryName)
  params: {
    name: containerRegistryName
    location: location
    acrSku: 'Premium'
    acrAdminUserEnabled: false
    anonymousPullEnabled: false
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
    exportPolicyStatus: 'enabled'
    publicNetworkAccess: 'Enabled'
    networkRuleSetDefaultAction: 'Allow'
    networkRuleBypassOptions: 'None'
    networkRuleSetIpRules: [
      for ip in firewallIpWhitelist: {
        value: ip
        action: 'Allow'
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

var sqlSrvName = format('sqlsrv-${dashedNameSuffix}')
var dbName = format('db-${dashedNameSuffix}')
module sqlSrvRes 'br/public:avm/res/sql/server:0.11.1' = {
  name: format(deployModulePattern, sqlSrvName)
  params: {
    name: sqlSrvName
    location: location
    publicNetworkAccess: 'Enabled'
    administratorLogin: useEntraOnlySqlAuthentications ? '' : sqlServerLogin
    administratorLoginPassword: useEntraOnlySqlAuthentications ? '' : sqlServerSecret
    administrators: {
      azureADOnlyAuthentication: useEntraOnlySqlAuthentications
      principalType: 'Application'
      login: sqlAdminMidRes.outputs.name
      sid: sqlAdminMidRes.outputs.clientId
      tenantId: tenant().tenantId
    }
    firewallRules: [
      for ip in firewallIpWhitelist: {
        name: format('fw-${ip}')
        startIpAddress: ip
        endIpAddress: ip
      }
    ]
    auditSettings: {
      state: 'Disabled'
    }
    databases: [
      {
        name: dbName
        // standard european collation (case-sensitive, accent-sensitive)
        collation: 'SQL_Latin1_General_CP1_CS_AS'
        // VCore model (General Purpose)
        sku: {
          name: 'GP_Gen5_2'
          tier: 'GeneralPurpose'
          family: 'Gen5'
          capacity: 2
        }
      }
    ]
    privateEndpoints: [
      {
        name: format('pep-${sqlSrvName}')
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: sqlServerPrivateDnsZone
              privateDnsZoneResourceId: privateDnsZoneSql.outputs.resourceId
            }
          ]
        }
        subnetResourceId: pepVNet.outputs.subnetResourceIds[0]
      }
    ]
  }
}

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
    internal: false
    zoneRedundant: false
    openTelemetryConfiguration: {
      samplingPercentage: 100
    }
    storages: [
      {
        shareName: fileShareName
        accessMode: 'ReadWrite'
        kind: 'SMB'
        storageAccountName: storageAccount.outputs.name
      }
    ]
  }
}

// outputs
output caeName string = caeName
output acrName string = containerRegistryName
output uaidName string = userAssignedIdentity.outputs.name
output acrLoginServer string = containerRegistry.outputs.loginServer
