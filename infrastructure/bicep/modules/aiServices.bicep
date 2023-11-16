param location string = 'CanadaCentral' // Hard coded because Canada East not supported yet
param aiServicesName string

resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
}
