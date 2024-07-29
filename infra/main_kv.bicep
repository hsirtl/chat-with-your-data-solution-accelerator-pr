targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

@description('Location for all resources.')
param location string

@description('Whether to use Key Vault to store secrets (best when using keys). If using RBAC, then please set this to false.')
param useKeyVault bool = authType == 'rbac' ? false : true

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Whether the Azure services communicate with each other using RBAC or keys. RBAC is recommended, however some users may not have sufficient permissions to assign roles.')
@allowed([
  'rbac'
  'keys'
])
param authType string = 'keys'

var tags = { 'azd-env-name': environmentName }
var rgName = 'rg-${environmentName}'
var keyVaultName = 'kv-${resourceToken}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

// Store secrets in a keyvault
module keyvault './core/security/keyvault.bicep' = if (useKeyVault || authType == 'rbac') {
  name: 'keyvault'
  scope: rg
  params: {
    name: keyVaultName
    location: location
    tags: tags
    principalId: principalId
  }
}
