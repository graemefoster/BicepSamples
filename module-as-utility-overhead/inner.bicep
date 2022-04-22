targetScope = 'resourceGroup'

param input int


//Purpose no-op to see the overhead of a module
module singleton 'get-singleton.bicep' = {
  name: 'get-singleton-${input}'
}

output output int = input
