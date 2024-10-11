param env string = 'dev'
param commonSubscription string
param appSubscription string

param commonRgNamePattern string
param commonRgLocation string
param commonRgTags object

param appRgNamePattern string
param appRgLocation string
param appRgTags object

targetScope = 'managementGroup'

module commonRg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'commonRg'
  scope: subscription(commonSubscription)
  params: {
    name: format(commonRgNamePattern, env)
    location: commonRgLocation
    tags: commonRgTags
  }
}

module appRg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'appRg'
  scope: subscription(appSubscription)
  params: {
    name: format(appRgNamePattern, env)
    location: appRgLocation
    tags: appRgTags
  }
}

// Outputs
output commonRgId string = commonRg.outputs.resourceId
output appRgId string = appRg.outputs.resourceId
