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
param openAiServiceName string
param aiContentSafetyName string
param aiSearchName string
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string

resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiServiceName
}

resource aiContentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiContentSafetyName
}

resource aiSearch 'Microsoft.Search/searchServices@2022-09-01' existing = {
  name: aiSearchName
}

var openAiServicesTarget = 'https://${openAiService.location}.api.cognitive.microsoft.com'
var aiContentSafetyTarget = 'https://${aiContentSafety.location}.api.cognitive.microsoft.com'
var aiSearchTarget = 'https://${aiSearch.location}.api.cognitive.microsoft.com'

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
    target: openAiServicesTarget
    credentials: {
      key: openAiService.listKeys().key1
    }
    isSharedToAll: true
  }
}

resource aiHubConnectionContentSafety 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
  name: 'Default_AzureAIContentSafety'
  parent: aiHub
  properties: {
    authType: 'ApiKey'
    category: 'CognitiveService'
    target: aiContentSafetyTarget
    credentials: {
      key: aiContentSafety.listKeys().key1
    }
    isSharedToAll: true
  }
}

resource aiHubConnectionAiSearch 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
  name: 'Default_AzureAISearch'
  parent: aiHub
  properties: {
    authType: 'ApiKey'
    category: 'CognitiveSearch'
    target: aiSearchTarget
    credentials: {
      key: openAiService.listKeys().key1
    }
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
