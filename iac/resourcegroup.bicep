targetScope = 'subscription'

param rgName string = 'rg-gbo-capplab-app-dev-01'
param location string = 'francecentral'
param env string = 'dev'
param tags object = {
  environment: env
  deployedBy: 'gbo'
  deployedFrom: 'azcli'
  deployedAt: utcNow()
}
param bdgAmount int = 40
param bdgThreshold int = 30
param notifiers array = ['gb@garaio.com']

module rg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: format('deploy-rg-${rgName}')
  params: {
     name: rgName
     location: location
     tags: tags
  }
}

module bdg 'br/public:avm/res/consumption/budget:0.3.5' = {
  name: 'deploy-budget'
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
