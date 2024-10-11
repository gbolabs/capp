param env string = 'dev'
param tags object = {}
param billingProfileName string


targetScope = 'tenant'

var dashedNameSuffix = 'capplab-{0}-${env}-01'
var deployModulePattern = 'capplab-sub.module-{0}'

var cmnSubName = format('sub-${dashedNameSuffix}','cmn')
var cmnSubModule = format(deployModulePattern, cmnSubName)
resource subCmn 'Microsoft.Subscription/subscriptionDefinitions@2017-11-01-preview' = {
  name: cmnSubModule
  scope: tenant()
  properties:{
    subscriptionDisplayName: cmnSubName
    
  }
}
