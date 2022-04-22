targetScope = 'resourceGroup'

param cycles int = 0

var input1 = 100
var input2 = 'Hello World!'

module singleton 'singleton.bicep' = {
  name: 'singleton'
  params: {
    input: 1234
  }
}

module inner 'inner.bicep' = [for idx in range(0, cycles): {
  name: 'inner${idx}'
  params: {
    input: idx
  }
  dependsOn: [
    singleton
  ]
}]

output output1 int = input1
output output2 string = input2
output innerOutputs array = [for idx in range(0, cycles): {
  innerOutput: inner[idx].outputs.output
}]
