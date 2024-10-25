targetScope = 'subscription'
@minLength(3)
param projectName string
@minLength(3)
param componentName string
@minLength(5)
@allowed([
  'francecentral'
  'swedencentral'
  'westeurope'
])
param location string = 'swedencentral'
@allowed([
  'dev'
  'test'
  'prod'
])
param env string = 'dev'
@description('The email address of the person responsible for the deployment')
@minLength(5)
param deployer string
@description('From where the deployment was done')
param source string
param date string = utcNow()
param bdgAmount int = 40
param bdgThreshold int = 30
param notifiers array = ['gb@garaio.com']


var seperator = '-'
var indexedResourcePattern = '{0}${seperator}${projectName}${seperator}${componentName}${seperator}${env}${seperator}{1}'
// var zeroedResourcePattern = '{0}${seperator}${projectName}${seperator}${componentName}${seperator}${env}${seperator}0'
// var blockResourcePattern = '{0}${projectName}${componentName}${env}{1}'

var tags = {
  environment: env
  deployedBy: deployer
  deployedFrom: source
  deployedAt: date
}

var rgName = format(indexedResourcePattern, 'rg', '0')
module rg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: format('deploy-rg-${rgName}')
  params: {
     name: rgName
     location: location
     tags: tags
  }
}

var bdgName = format(indexedResourcePattern, 'bdg',bdgAmount)
module bdg 'br/public:avm/res/consumption/budget:0.3.5' = {
  name: bdgName
  scope: subscription(subscription().subscriptionId)
  params: {
    amount: bdgAmount
    category: 'Cost'
    name: 'budget-${rgName}'
    resourceGroupFilter: [
      rg.outputs.name
    ]
    thresholdType: 'Forecasted'
    thresholds: [
      {
        operator: 'GreaterThan'
        amount: bdgThreshold
      }
    ]
    contactEmails: notifiers
  }
}
