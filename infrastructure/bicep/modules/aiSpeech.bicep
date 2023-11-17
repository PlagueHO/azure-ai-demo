param location string
param aiSpeechName string
@allowed([
  'S0'
])
param sku string = 'S0'
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string

resource aiSpeech 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiSpeechName
  location: location
  sku: {
    name: sku
  }
  kind: 'SpeechServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Add the diagnostic settings to send logs and metrics to Log Analytics
resource aiSpeechDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${logAnalyticsWorkspaceName}'
  scope: aiSpeech
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false 
        }
      }
      {
        category: 'RequestResponse'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false 
        }
      }
      {
        category: 'Trace'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false 
        }
      }
    ]
    metrics:[
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output aiSpeechId string = aiSpeech.id
output aiSpeechName string = aiSpeech.name
output aiSpeechEndpoint string = aiSpeech.properties.endpoint
