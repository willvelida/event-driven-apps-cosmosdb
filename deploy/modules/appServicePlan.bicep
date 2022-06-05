@description('The name of our App Service Plan')
param appServicePlanName string

@description('The location to deploy our App Service Plan')
param location string

@description('The SKU that we will provision this App Service Plan to.')
param appServicePlanSkuName string

@description('The tier that this App Service Plan will use')
param appServicePlanTier string

@description('The max number of workers in this app service plan')
param maxWorkerCount int

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanTier
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: maxWorkerCount
  } 
}

output appServicePlanId string = appServicePlan.id
