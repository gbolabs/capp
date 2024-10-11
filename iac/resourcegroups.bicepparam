using 'resourcegroups.bicep'

var location = 'francecentral'
var rgNamePattern = 'rg-gbo-capplab-{0}-{1}-01'
var rgTags = {
  deployedBy: 'gbo'
  deployedFrom: 'AzCLI'
  deployedOn: '2024-10-08'
  purpose: 'Lab-delete-as-needed'
}

param appRgLocation =  location

param appRgNamePattern =  format(rgNamePattern, 'app', '{0}')

param appRgTags = rgTags

param appSubscription = '199fc2c4-a57c-4049-afbe-e1831f4b2f6e'

param commonSubscription =  'ce167e67-9065-4703-ae02-b0ee721302a9'

param commonRgLocation =  location

param commonRgNamePattern =  format(rgNamePattern, 'cmn', '{0}')

param commonRgTags =  rgTags
  