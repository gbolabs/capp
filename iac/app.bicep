param location string = resourceGroup().location
param env string = 'dev'
param dashedNameSuffix string = 'capplab-${env}-03'

param caeEnvName string
param acrName string
param uaidName string
param containerImageRepository string
param containerImageTag string
param secretName string
param vaultName string

param customDnsZoneName string
param customDnsZoneResourceGroup string
param customDnsZoneSubscriptionId string

var deployModulePattern = 'capp-module-{0}'
var memorySize = '1.0Gi'
var apiCappName = format('cap-api-${dashedNameSuffix}')
var webCappName = format('cap-web-${dashedNameSuffix}')
var carboneCappName = format('cap-carbone-${dashedNameSuffix}')
var ingressCappName = format('cap-ingress-${dashedNameSuffix}')
var azcliCappName = format('cap-azcli-${dashedNameSuffix}')

resource cae 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: caeEnvName
}
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}
resource uaid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: uaidName
}
module ingressCnameRecord 'br/public:avm/res/network/dns-zone:0.5.0' = {
  name: 'ingress-cname-record'
  scope: resourceGroup(customDnsZoneSubscriptionId,customDnsZoneResourceGroup)
  params: {
    name: customDnsZoneName
    cname: [
      {
        name: 'gbocaplab'
        ttl: 300
        cnameRecord: { cname: cappIngress.outputs.fqdn }
      }
    ]
  }
}

module cappCarbone 'br/public:avm/res/app/container-app:0.11.0' = {
  name: format(deployModulePattern, carboneCappName)
  params: {
    name: carboneCappName
    location: location
    environmentResourceId: cae.id
    disableIngress: false
    ingressExternal: false
    ingressTargetPort: 4000
    ingressTransport: 'http'
    scaleMinReplicas: 2
    scaleMaxReplicas: 8
    managedIdentities: {
      userAssignedResourceIds: [
        uaid.id
      ]
    }
    registries: [
      {
        identity: uaid.id
        server: acr.properties.loginServer
      }
    ]
    volumes:[
      {
        name: 'carbone'
        storageType: 'EmptyDir'
      }
    ]
    // scaleRules: [
    //   {
    //     metricName: 'cpu'
    //     metricThreshold: 80
    //     scaleDirection: 'out'
    //     scaleStep: 1
    //     cooldown: 'PT1M'
    //   }
    //   {
    //     metricName: 'cpu'
    //     metricThreshold: 20
    //     scaleDirection: 'in'
    //     scaleStep: 1
    //     cooldown: 'PT1M'
    //   }
    // ]
    containers: [
      {
        image: '${acr.properties.loginServer}/${containerImageRepository}/carbone:latest'
        name: 'carbone'
        resources: {
          memory: memorySize
          cpu: json('0.5')
        }
        volumeMounts: [
          {
            volumeName: 'carbone'
            subPath: 'render'
            mountPath: '/app/render'
          }
          {
            volumeName: 'carbone'
            subPath: 'template'
            mountPath: '/app/template'
          }
        ]
      }
    ]
  }
}

module cappApi 'br/public:avm/res/app/container-app:0.11.0' = {
  name: format(deployModulePattern, apiCappName)
  params: {
    name: apiCappName
    location: location
    environmentResourceId: cae.id
    managedIdentities: {
      userAssignedResourceIds: [
        uaid.id
      ]
    }
    disableIngress: false
    ingressExternal: false
    ingressAllowInsecure: false
    ingressTargetPort: 8080
    scaleMinReplicas: 1
    scaleMaxReplicas: 2
    ingressTransport: 'http'
    registries: [
      {
        identity: uaid.id
        server: acr.properties.loginServer
      }
    ]
    containers: [
      {
        image: '${acr.properties.loginServer}/${containerImageRepository}/api:${containerImageTag}'
        name: 'api'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          {
            name: 'CARBONE_URL'
            value: 'https://${cappCarbone.outputs.fqdn}'
          }
          { name: 'KEYVAULT_NAME', value: vaultName }
        ]
      }
    ]
  }
}

module cappWeb 'br/public:avm/res/app/container-app:0.11.0' = {
  name: format(deployModulePattern, webCappName)
  params: {
    name: webCappName
    location: location
    environmentResourceId: cae.id
    managedIdentities: {
      userAssignedResourceIds: [
        uaid.id
      ]
    }
    disableIngress: false
    ingressExternal: false
    ingressAllowInsecure: false
    ingressTargetPort: 80
    ingressTransport: 'http'
    scaleMinReplicas: 1
    scaleMaxReplicas: 2
    registries: [
      {
        identity: uaid.id
        server: acr.properties.loginServer
      }
    ]
    containers: [
      {
        image: '${acr.properties.loginServer}/${containerImageRepository}/web:${containerImageTag}'
        name: 'web'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
      }
    ]
  }
}

module cappIngress 'br/public:avm/res/app/container-app:0.11.0' = {
  name: format(deployModulePattern, ingressCappName)
  params: {
    name: ingressCappName
    location: location
    environmentResourceId: cae.id
    managedIdentities: {
      userAssignedResourceIds: [
        uaid.id
      ]
    }
    customDomains: [
      {
        name: 'gbocaplab'
        zoneName: customDnsZoneName
        zoneResourceGroup: customDnsZoneResourceGroup
        zoneSubscriptionId: customDnsZoneSubscriptionId
      }
    ]
    ingressExternal: true
    disableIngress: false
    ingressAllowInsecure: false
    ingressTargetPort: 80
    ingressTransport: 'http'
    scaleMinReplicas: 1
    scaleMaxReplicas: 2
    registries: [
      {
        identity: uaid.id
        server: acr.properties.loginServer
      }
    ]
    containers: [
      {
        image: '${acr.properties.loginServer}/${containerImageRepository}/ingress:${containerImageTag}'
        name: 'ingress'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          { name: 'CAPP_API_HOST', value: cappApi.outputs.fqdn }
          { name: 'CAPP_API_PORT', value: '443' }
          { name: 'CAPP_API_SCHEME', value: 'https' }
          { name: 'CAPP_WEB_HOST', value: cappWeb.outputs.fqdn }
          { name: 'CAPP_WEB_PORT', value: '443' }
          { name: 'CAPP_WEB_SCHEME', value: 'https' }
          { name: 'CAPP_CARBONE_HOST', value: cappCarbone.outputs.fqdn }
          { name: 'CAPP_CARBONE_PORT', value: '443' }
          { name: 'CAPP_CARBONE_SCHEME', value: 'https' }
        ]
      }
    ]
  }
}

module cappAzcli 'br/public:avm/res/app/container-app:0.11.0' = {
  name: format(deployModulePattern, azcliCappName)
  params: {
    name: azcliCappName
    location: location
    environmentResourceId: cae.id
    managedIdentities: {
      userAssignedResourceIds: [
        uaid.id
      ]
    }
    disableIngress: true
    ingressExternal: false
    ingressAllowInsecure: false
    ingressTargetPort: 80
    ingressTransport: 'http'
    scaleMinReplicas: 1
    scaleMaxReplicas: 2
    registries: [
      {
        identity: uaid.id
        server: acr.properties.loginServer
      }
    ]
    containers: [
      {
        image: '${acr.properties.loginServer}/${containerImageRepository}/azcli:${containerImageTag}'
        name: 'azcli'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          { name: 'SECRET_NAME', value: secretName }
          { name: 'VAULT_NAME', value: vaultName }
          { name: 'SUBSCRIPTION_ID', value: subscription().subscriptionId }
          { name: 'TENANT_ID', value: tenant().tenantId }
          { name: 'IDENTITY_CLIENT_ID', value: uaid.properties.clientId }
        ]
      }
    ]
  }
}
