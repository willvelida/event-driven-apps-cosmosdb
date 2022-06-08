@description('The location where we will deploy our resources to. Default is the location of the resource group')
param location string = resourceGroup().location

@description('Name of our application.')
param applicationName string = uniqueString(resourceGroup().id)

var appServicePlanName = '${applicationName}asp'
var appServicePlanSkuName = 'EP1'
var appServicePlanTierName = 'ElasticPremium'
var workerCount = 20
var storageAccountName = 'fnstor${replace(applicationName, '-', '')}'
var storageSku = 'Standard_LRS'
var functionAppName = '${applicationName}func'
var functionRuntime = 'dotnet'
var cosmosDbAccountName = '${applicationName}db'
var databaseName = 'ReadingsDb'
var writeContainerName = 'Readings'
var readContainerName = 'Locations'
var leaseContainerName = 'leases'
var containerThroughput = 4000
var appInsightsName = '${applicationName}ai'
var eventHubsName = '${applicationName}eh'
var eventHubsSkuName = 'Basic'
var hubName = 'readings'
var keyVaultName = '${applicationName}kv'
var keyVaultSku = 'standard'
var logAnalyticsWorkspaceName = '${applicationName}law'

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module cosmosDb 'modules/cosmosDb.bicep' = {
  name: 'cosmosDb'
  params: {
    writeContainerName: writeContainerName
    readContainerName: readContainerName
    containerThroughput: containerThroughput
    cosmosDbAccountName: cosmosDbAccountName
    leaseContainerName: leaseContainerName
    databaseName: databaseName
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspace: logAnalyticsWorkspaceName
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    appServicePlanName: appServicePlanName 
    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanTier: appServicePlanTierName
    maxWorkerCount: workerCount
    location: location
  }
}

module eventHub 'modules/eventHubs.bicep' = {
  name: 'eventHub'
  params: {
    eventHubsName: eventHubsName 
    eventHubsSkuName: eventHubsSkuName
    hubName: hubName
    location: location
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    appInsightsName: appInsightsName 
    cosmosDbEndpoint: cosmosDb.outputs.cosmosDbEndpoint
    databaseName: cosmosDb.outputs.databaseName
    eventHubName: eventHub.outputs.eventHubName
    eventHubNamespaceName: eventHub.outputs.eventHubNamespaceName
    functionAppName: functionAppName
    functionRuntime: functionRuntime
    leaseContainerName: cosmosDb.outputs.leaseContainerName
    location: location
    readContainerName: cosmosDb.outputs.readContainerName 
    serverFarmId: appServicePlan.outputs.appServicePlanId
    storageAccountName: storageAccountName
    storageSku: storageSku
    writeContainerName: cosmosDb.outputs.writeContainerName
  }
}

module eventHubRoles 'modules/eventHubRoleAssignment.bicep'  = {
  name: 'eventhubsroles'
  params: {
    eventHubNamespaceName: eventHub.outputs.eventHubNamespaceName 
    functionAppId: functionApp.outputs.functionAppId
    functionAppPrincipalId: functionApp.outputs.functionAppPrincipalId
  }
}

module sqlRoleAssignment 'modules/sqlRoleAssignment.bicep' = {
  name: 'sqlRoleAssignment'
  params: {
    cosmosDbAccountName: cosmosDb.outputs.cosmosDbAccountName
    functionAppPrincipalId: functionApp.outputs.functionAppPrincipalId
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      
    ]
    enabledForDeployment: true
    softDeleteRetentionInDays: 7
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.outputs.functionAppPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          keys: [
            'all'
          ]
        }
        tenantId: functionApp.outputs.functionAppTenantId
      }
    ]
  }
}
