// param config object
param tags object

param name string
param location string = resourceGroup().location
param ignoreResourceIdentifier bool = false

@description('Whether access via shared key is allowed vs using Azure RBAC')
param allowSharedKeyAccess bool = false

@description('Not that this allows blobs to be marked as public, not requiring authentication. This is distinct from public access from the internet')
param allowBlobPublicAccess bool = false

param supportsHttpsTrafficOnly bool = true

//minLength(3)
@maxLength(63)
param containerName string = ''

//minLength(3)
@maxLength(63)
param fileShareName string = ''

param skuName string = 'Standard_LRS'
param kind string = 'StorageV2'
param accessTier string = 'Hot'

@description('Private endpoint subnet. Explicitly pass \'public\' for public access, or empty for private storage with private endpoints to be set up later')
param subnetId string

@description('If specified, this overrides the default nacl policy which denies external access if using privatelink or allows external access if we are exposing directly to internet')
param networkAcls object = {}

// Public nacl is open to everyone
var defaultPublicNacls = {
  ipRules: []
  virtualNetworkRules: []
}

// Private nacl is deny access to public internet, but allow access to Azure services (and private endpoints)
var defaultPrivateNacls = union(defaultPublicNacls, {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
})

// If the user specified nacls specifically, use them. Otherwise pick a sensible default based on whether using private link or not.
// In cases where this resource will be projected into other subscriptions (e.g. a log analytics storage account shared by multiple subs)
// then it makes sense to have a private nacl with no endpoints set up yet.
var resolvedNetworkAcls = (networkAcls == {}) ? (subnetId == 'public' ? defaultPublicNacls : defaultPrivateNacls) : networkAcls


//variables
// var env = config.environment.value
// var resourceTags = union(config.tagsObject.value, tags)
// var resourceType = config.resourceTypesObject.value['storageAccount']
// var resourceIdentifier = config.environmentsObject.value[env].namingScheme.regional
// var resName = ignoreResourceIdentifier ? '${name}${resourceType}' : '${resourceIdentifier}${resourceType}${name}'
// var resNameSanitized = toLower(replace(resName, '-', ''))

// //storage account name must be between 3 and 24 characters in length
// var resourceName = length(resNameSanitized) > 24 ? take(resNameSanitized, 24) : resNameSanitized
// var retentionInDays = config.environmentsObject.value[env].logRetentionInDays

var resourceName = name
var resourceTags = tags
var retentionInDays = 30

resource sto 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: resourceName
  location: location
  tags: resourceTags

  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    networkAcls: resolvedNetworkAcls

    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: '${sto.name}/default'
  properties: {
    isVersioningEnabled: true
    containerDeleteRetentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    deleteRetentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    changeFeed: {
      enabled: true
    }
    restorePolicy: {
      days: retentionInDays - 1
      enabled: true
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  name: '${sto.name}/default'
  properties: {
    shareDeleteRetentionPolicy: {
      days: retentionInDays
      enabled: true
    }
  }
  dependsOn: [
    blobServices
  ]
}

resource stoContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = if (!empty(containerName)) {
  name: !empty(containerName) ? '${sto.name}/default/${toLower(containerName)}' : '${sto.name}/default/container'
  properties: {
    publicAccess: allowBlobPublicAccess ? 'Blob' : 'None'
  }
  dependsOn: [
    blobServices
  ]
}

resource stoFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = if (!empty(fileShareName)) {
  name: !empty(fileShareName) ? '${sto.name}/default/${toLower(fileShareName)}' : '${sto.name}/default/share'
  dependsOn: [
    fileServices
  ]
}


// Outputs
output id string = sto.id
output name string = sto.name
output uri string = sto.properties.primaryEndpoints.blob

// ------------------------------
// Deprecated
// Use the individual, typed outputs above instead of the resource object
// This allows for more bugs to be caught at compile-time
output resource object = {
  id: sto.id
  name: sto.name
  resourceGroupName: resourceGroup().name
  subscriptionId: subscription().subscriptionId
  uri: sto.properties.primaryEndpoints.blob
}
