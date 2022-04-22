param location string = resourceGroup().location

@secure()
param password string

resource pg 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  location: location
  name: 'pgsingleserver${uniqueString('subscription-${resourceGroup().name}')}'
  properties: {
    createMode: 'Default'
    publicNetworkAccess: 'Enabled'
    administratorLogin: 'pgadmin'
    administratorLoginPassword: password
    version: '11'
    storageProfile: {
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
      backupRetentionDays: 30
    }
  }

  resource db 'databases@2017-12-01-preview' = {
    name: 'mydb'
  }
}

resource pg4 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  location:  location
  name: 'pgsingleserverpitr2${uniqueString('subscription-${resourceGroup().name}')}'
  properties: {
    createMode: 'PointInTimeRestore'
    sourceServerId: pg.id
    restorePointInTime: '2022-04-21T10:22:55.5277241+08:00'
    storageProfile: {
      geoRedundantBackup: 'Enabled'
      backupRetentionDays: 30
    }
  }
}


