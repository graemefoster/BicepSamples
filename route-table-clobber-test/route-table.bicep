resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  location: 'australiaeast'
  name: 'myrt'
  properties: {
    routes: [
      {
        id: 'myrt-route'
        name: 'route1'
        properties: {
          nextHopType: 'None'
          addressPrefix: '10.0.1.15/32'
        }
      }
    ]
  }
}
