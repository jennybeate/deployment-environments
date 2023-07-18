@description('The Geo-location where the resource lives')
param location string = resourceGroup().location

@description('Tags for resource')
param tags object = resourceGroup().tags

@description('Name of existing sql server to set as parent for database')
param name string

@description('Sql server version')
param version string = '12.0'

@description('Optional. The virtual network rules to create in the server.')
param virtualNetworkRules array = []

@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints array = []

@description('Optional. The firewall rules to create in the server.')
param firewallRules array = []

@allowed([
  'Disabled'
  'Enabled'
])
@description('Whether or not public endpoint access is allowed for this server. Default Enabled')
param publicNetworkAccess string ='Enabled'

@description('Conditional. The administrator username for the server. Required if no `administrators` object for AAD authentication is provided.Can be the login name and object id of an Azure AD security group')
param administratorLogin string = ''

@description('Conditional. The Azure Active Directory (AAD) administrator authentication. Required if no `administratorLogin` & `administratorLoginPassword` is provided.')
param administrators object = {}

@description('Conditional. The administrator login password. Required if no `administrators` object for AAD authentication is provided. ')
@secure()
param administratorLoginPassword string = ''

@description('Only allow authentication to sql server using Azure AD')
param azureADonlyAuthentication bool = true

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Conditional. The resource ID of a user assigned identity to be used by default. Required if "userAssignedIdentities" is not empty.')
param primaryUserAssignedIdentityId string = ''

///vars//


var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var _identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null



resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: name
  location: location
  tags: tags
  identity: _identity
  properties: {
    
      administratorLogin: !empty(administratorLogin) ? administratorLogin : null
        administratorLoginPassword: !empty(administratorLoginPassword) ? administratorLoginPassword : null
        administrators: !empty(administrators) ? {
          administratorType: 'ActiveDirectory'
          azureADOnlyAuthentication: azureADonlyAuthentication
          login: administrators.loginName
          principalType: 'Group'
          sid: administrators.objectId
          tenantId: tenant().tenantId
        } : null 
    
      minimalTlsVersion: '1.2'
      version: version
      primaryUserAssignedIdentityId: !empty(primaryUserAssignedIdentityId) ? primaryUserAssignedIdentityId : null
      publicNetworkAccess: !empty(publicNetworkAccess) ? any(publicNetworkAccess) : (!empty(privateEndpoints) && empty(firewallRules) && empty(virtualNetworkRules) ? 'Disabled' : null) 
   
  }
}


@description('resource output')
output name string = sqlServer.name
output id string = sqlServer.id
//output resource resource = sqlServer
