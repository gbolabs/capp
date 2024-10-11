using 'infra.main.bicep'

param location = 'switzerlandnorth'
param env = 'dev'
param dashedNameSuffix = 'capplab-${env}-01'
param blockNameSuffix = 'capplabgbo${env}01'
param remoteIp = '46.126.84.53'
param pushUserId = '74fa1dc1-96ae-4b65-9905-9004b475ff9d'
param budgetAmount = 20
param budgetNotificationEmail = 'gb@garaio.com'
