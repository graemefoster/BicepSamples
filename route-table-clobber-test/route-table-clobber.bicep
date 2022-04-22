resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  location: 'australiaeast'
  name: 'myrt'
  properties: {
    routes: []
  }
}
