param location string
param aiServicesName string
@allowed([
  'F0'
  'S0'
])
param sku string = 'S0'
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  sku: {
    name: sku
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Add the diagnostic settings to send logs and metrics to Log Analytics
resource aiServicesDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${logAnalyticsWorkspaceName}'
  scope: aiServices
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

output aiServicesId string = aiServices.id
output aiServicesName string = aiServices.name
