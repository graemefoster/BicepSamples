targetScope = 'resourceGroup'

param name string = 'logicapptest'
param location string = resourceGroup().location

var uniqueName = '${name}${substring(uniqueString(resourceGroup().id), 0, 5)}'

resource logaw 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${uniqueName}-logaw'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource logicPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${uniqueName}-logicapp-plan'
  location: location
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  properties: {
    targetWorkerCount: 1
    maximumElasticWorkerCount: 2
    elasticScaleEnabled: true
    isSpot: false
    zoneRedundant: true
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: '${uniqueName}-appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    RetentionInDays: 30
    WorkspaceResourceId: logaw.id
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${uniqueName}logicstg'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// App service containing the workflow runtime
resource site 'Microsoft.Web/sites@2021-02-01' = {
  name: '${uniqueName}-logicapp'
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'app-${toLower(name)}-logicservice'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appi.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appi.properties.ConnectionString
        }
      ]
      use32BitWorkerProcess: true
    }
    serverFarmId: logicPlan.id
    clientAffinityEnabled: false
  }
}

// Return the Logic App service name and farm name
output app string = site.name
output plan string = logicPlan.name
