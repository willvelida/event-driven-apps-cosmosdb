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

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' = {
  name: cosmosDbAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
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
  }
  identity: {
    type: 'SystemAssigned'
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
      throughput: containerThroughput
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

output cosmosDbAccountName string = cosmosDbAccount.name
output databaseName string = database.name
output writeContainerName string = writeContainer.name
output readContainerName string = readContainer.name
output leaseContainerName string = leaseContainer.name
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
