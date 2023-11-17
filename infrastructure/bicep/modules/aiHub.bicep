param location string
param aiHubName string
@allowed([
  'Basic'
])
param sku string = 'Basic'
param storageAccountId string
param keyVaultId string
param applicationInsightsId string
param containerRegistryId string
param openAiTarget string = 'https://canadacentral.api.cognitive.microsoft.com/'
param contentSafetyTarget string = 'https://canadaeast.api.cognitive.microsoft.com/'
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiHubName
  location: location
  sku: {
    name: sku
    tier: sku
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Services Hub (${location})'
    publicNetworkAccess: 'Enabled'
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id
    }
  }
}

resource aiHubConnectionOpenAi 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
  name: 'Default_AzureOpenAI'
  parent: aiHub
  properties: {
    authType: 'ApiKey'
    category: 'AzureOpenAI'
    target: openAiTarget
    isSharedToAll: true
  }
}

resource aiHubConnectionContentSafety 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
  name: 'Default_AzureAIContentSafety'
  parent: aiHub
  properties: {
    authType: 'ApiKey'
    category: 'CognitiveService'
    target: contentSafetyTarget
    isSharedToAll: true
  }
}

// Add the diagnostic settings to send logs and metrics to Log Analytics
resource aiHubDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${logAnalyticsWorkspaceName}'
  scope: aiHub
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: []
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

output aiHubId string = aiHub.id
output aiHubName string = aiHub.name
