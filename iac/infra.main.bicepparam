using 'infra.main.bicep'

param location = 'switzerlandnorth'
param env = 'dev'
param dashedNameSuffix = 'capplab-${env}-01'
param blockNameSuffix = 'capplabgbo${env}01'
param remoteIp = ' '
param pushUserId = ' '
param budgetAmount = 20
param budgetNotificationEmail = ' '
