resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'priv-ip-vnet'
  location: 'australiaeast'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: 'aci-subnet'
  parent: vnet
  properties: {
    addressPrefix: '10.0.0.0/24'
    delegations: [
      {
        name: 'DelegationService'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}

resource containergroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: 'priv-ip-test'
  location: 'australiaeast'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    containers: [
      {
        name: 'testcontainerone'
        properties: {
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    ipAddress: {
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
      type: 'Private'
    }
    subnetIds: [
      {
        id: subnet.id
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
  }
}
