@description('The principal Id of the GitHub Actions SP that this role will be granted to')
param gitHubActionsPrincipalId string

@description('The name of this Key Vault that this role will be granted to.')
param keyVaultName string

var roleName = 'Key Vault resource manager template deployment operator'
var roleDesciption = 'Lets you deploy a resource manager template with the access to the secrets in the Key Vault.'
var actions = [
  'Microsoft.KeyVault/vaults/deploy/action'
]
var notActions = []

var roleDefName = guid(subscription().id, string(actions), string(notActions))

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDesciption
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

resource keyVaultDeploymentRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, gitHubActionsPrincipalId, roleDefinition.id)
  scope: keyVault
  properties: {
    principalId: gitHubActionsPrincipalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}
