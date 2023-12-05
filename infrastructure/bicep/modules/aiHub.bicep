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
param aiSpeechName string
param aiSearchName string
param logAnalyticsWorkspaceId string
param logAnalyticsWorkspaceName string

resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiServiceName
}

resource aiContentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiContentSafetyName
}

resource aiSpeech 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiSpeechName
}

resource aiSearch 'Microsoft.Search/searchServices@2022-09-01' existing = {
  name: aiSearchName
}

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
    systemDatastoresAuthMode: 'accessKey'
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id
    }
  }
}

// TODO: Once APIs are published, should be able to remove this
#disable-next-line BCP081
resource aiHubOpenAiEndpoint 'Microsoft.MachineLearningServices/workspaces/endpoints@2023-08-01-preview' = {
  name: 'Azure.OpenAI'
  parent: aiHub
  properties: {
    name: 'Azure.OpenAI'
    endpointType: 'Azure.OpenAI'
    associatedResourceId: openAiService.id
    credential: 'APi'
    key: 'apc'
  }
}

// TODO: Once APIs are published, should be able to remove this
#disable-next-line BCP081
resource aiHubContentSafetyEndpoint 'Microsoft.MachineLearningServices/workspaces/endpoints@2023-08-01-preview' = {
  name: 'Azure.ContentSafety'
  parent: aiHub
  properties: {
    name: 'Azure.ContentSafety'
    endpointType: 'Azure.ContentSafety'
    associatedResourceId: aiContentSafety.id
  }
}

// TODO: Once APIs are published, should be able to remove this
#disable-next-line BCP081
resource aiHubSpeechEndpoint 'Microsoft.MachineLearningServices/workspaces/endpoints@2023-08-01-preview' = {
  name: 'Azure.Speech'
  parent: aiHub
  properties: {
    name: 'Azure.Speech'
    location: location
    endpointType: 'Azure.Speech'
    associatedResourceId: aiSpeech.id
  }
}

// var openAiServicesTarget = 'https://${openAiService.location}.api.cognitive.microsoft.com'
// var aiContentSafetyTarget = 'https://${aiContentSafety.location}.api.cognitive.microsoft.com'
// var aiSearchTarget = 'https://${aiSearch.location}.api.cognitive.microsoft.com'

// resource aiHubConnectionOpenAi 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
//   name: 'Default_AzureOpenAI'
//   parent: aiHub
//   properties: {
//     authType: 'ApiKey'
//     category: 'AzureOpenAI'
//     target: openAiServicesTarget
//     credentials: {
//       key: openAiService.listKeys().key1
//     }
//     isSharedToAll: true
//   }
// }

// resource aiHubConnectionContentSafety 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
//   name: 'Default_AzureAIContentSafety'
//   parent: aiHub
//   properties: {
//     authType: 'ApiKey'
//     category: 'CognitiveService'
//     target: aiContentSafetyTarget
//     credentials: {
//       key: aiContentSafety.listKeys().key1
//     }
//     isSharedToAll: true
//   }
// }

// resource aiHubConnectionAiSearch 'Microsoft.MachineLearningServices/workspaces/connections@2023-08-01-preview' = {
//   name: 'Default_AzureAISearch'
//   parent: aiHub
//   properties: {
//     authType: 'ApiKey'
//     category: 'CognitiveSearch'
//     target: aiSearchTarget
//     credentials: {
//       key: openAiService.listKeys().key1
//     }
//     isSharedToAll: true
//   }
// }

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
