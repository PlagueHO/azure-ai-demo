param location string = 'CanadaCentral' // Hard coded because Canada East not supported yet
param aiServicesName string

resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
}
