targetScope = 'resourceGroup'

resource singleton 'Microsoft.Resources/deployments@2021-04-01' existing = {
  name: 'singleton'
}

var outputs =  singleton.properties.outputs
output output1 int = outputs.output.value
