@description('The location that these Cosmos DB resources will be deployed to')
param location string

@description('The name of our Cosmos DB Account')
param cosmosDbAccountName string

@description('The name of our Database')
param databaseName string

@description('The name of our write container')
param writeContainerName string

@description('The name of our read container')
param readContainerName string

@description('The name of our lease container')
param leaseContainerName string

@description('The amount of throughput to provision in our Cosmos DB Container')
param containerThroughput int

@description('The name of the key vault to store secrets in')
param keyVaultName string

@description('The name of the Log Analytics workspace to send logs to.')
param logAnalyticsWorkspace string

var connectionStringSecretName = 'CosmosDbConnectionString'
var leaseContainerThroughput = 400

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspace
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' = {
  name: cosmosDbAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAnalyticalStorage: true
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    backupPolicy: {
      type: 'Continuous'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource diagnosticMetric 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${cosmosDbAccountName}-diagnostics'
  scope: cosmosDbAccount
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-11-15-preview' = {
  name: databaseName
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource writeContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-11-15-preview' = {
  name: writeContainerName
  parent: database
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: containerThroughput
      }
    }
    resource: {
      id: writeContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      defaultTtl: 600
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

resource readContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-11-15-preview' = {
  name: readContainerName
  parent: database
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: containerThroughput
      }
    }
    resource: {
      id: readContainerName
      partitionKey: {
        paths: [
          '/Location'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

resource leaseContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-11-15-preview' = {
  name: leaseContainerName
  parent: database
  properties: {
    options: {
      throughput: leaseContainerThroughput
    }
    resource: {
      id: leaseContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: connectionStringSecretName
  parent: keyVault
  properties: {
    value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output cosmosDbAccountName string = cosmosDbAccount.name
output cosmosDbId string = cosmosDbAccount.id
output databaseName string = database.name
output writeContainerName string = writeContainer.name
output readContainerName string = readContainer.name
output leaseContainerName string = leaseContainer.name
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
