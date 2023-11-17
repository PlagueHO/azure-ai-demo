param location string
param aiContentSafetyName string
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string
@allowed([
  'F0'
  'S0'
])
param sku string = 'F0'

resource aiContentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiContentSafetyName
  location: location
  sku: {
    name: sku
  }
  kind: 'ContentSafety'
  identity: {
    type: 'SystemAssigned'
  }
}

// Add the diagnostic settings to send logs and metrics to Log Analytics
resource openAiServiceDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${logAnalyticsWorkspaceName}'
  scope: aiContentSafety
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

output aiContentSafetyName string = aiContentSafety.name
