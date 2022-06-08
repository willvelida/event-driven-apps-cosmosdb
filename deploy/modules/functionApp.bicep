@description('The name of the function')
param functionAppName string

@description('The runtime that this Function will use')
param functionRuntime string

@description('The location to deploy the Function to.')
param location string

@description('The App Plan that this Function App will be provisioned to.')
param serverFarmId string

@description('The name of the Storage Account that this Function will use')
param storageAccountName string

@description('The SKU that this storage account will use')
param storageSku string

@description('The name of the Application Insights Instance that this Function will use.')
param appInsightsName string

param databaseName string
param writeContainerName string
param readContainerName string
param leaseContainerName string

param cosmosDbEndpoint string
param eventHubNamespaceName string
param eventHubName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'DatabaseName'
          value: databaseName
        }
        {
          name: 'WriteContainer'
          value: writeContainerName
        }
        {
          name: 'ReadContainer'
          value: readContainerName
        }
        {
          name: 'leases'
          value: leaseContainerName
        }
        {
          name: 'CosmosDbEndpoint__accountEndpoint'
          value: cosmosDbEndpoint
        }
        {
          name: 'CosmosDBEndpoint__credential'
          value: 'managedIdentity'
        }
        {
          name: 'EventHubConnection__fullyQualifiedNamespace'
          value: '${eventHubNamespaceName}.servicebus.windows.net'
        }
        {
          name: 'ReadingsEventHub'
          value: eventHubName
        }
      ]
    }
    httpsOnly: true
  } 
  identity: {
    type: 'SystemAssigned'
  }
}

output functionAppId string = functionApp.id
output functionAppPrincipalId string = functionApp.identity.principalId
output functionAppTenantId string = functionApp.identity.tenantId
