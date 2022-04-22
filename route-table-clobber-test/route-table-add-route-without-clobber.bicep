resource rt 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: 'myrt'

  resource route1 'routes@2021-05-01' = {
    name: 'rt-2'
    properties: {
      nextHopType: 'VirtualAppliance'
      addressPrefix: '10.2.0.0/21'
      nextHopIpAddress: '10.2.0.15'
    }
  }

}
