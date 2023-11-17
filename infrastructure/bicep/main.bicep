targetScope = 'subscription'

@description('The location to deploy the AI Services into.')
@allowed([
  'AustraliaEast'
  'CanadaEast'
  'EastUS'
  'EastUS2'
  'FranceCentral'
  'JapanEast'
  'NorthCentralUS'
  'SouthCentralUS'
  'SwedenCentral'
  'SwitzerlandNorth'
  'WestEurope'
  'UKSouth'
])
param location string = 'CanadaEast'

@description('The name of the resource group that will contain all the resources.')
param resourceGroupName string

@description('The base name that will prefixed to all Azure resources deployed to ensure they are unique.')
param baseResourceName string

@description('The base code that will postfixed to all Azure resources deployed to ensure they are unique.')
param locationCode string = 'cae'

var logAnalyticsWorkspaceName = '${baseResourceName}-${locationCode}-loganalyticsworkspace'
var applicationInsightsName = '${baseResourceName}-${locationCode}-appinsights'
var keyVaultName = '${baseResourceName}-keyvault'
var openAiServiceName = '${baseResourceName}-${locationCode}-openai'
var aiSpeechName = '${baseResourceName}-${locationCode}-aispeech'
var aiContentSafetyName = '${baseResourceName}-${locationCode}-aicontentsafety'
var aiServicesName = '${baseResourceName}-cac-aiservices'
var aiServicesLocation = 'Canada Central' // AI services is not supported in default Canada East region
var aiSearchName = '${baseResourceName}-${locationCode}-aisearch'
var containerRegistryName = replace('${baseResourceName}${locationCode}cr','-','')
var storageAccountName = replace('${baseResourceName}${locationCode}data','-','')
var aiHubName = '${baseResourceName}-${locationCode}-aihub'

var openAiModelDeployments = [
  {
    name: 'gpt-35-turbo'
    modelName: 'gpt-35-turbo'
    version: '0613'
    sku: 'Standard'
    capacity: 60
  }
  {
    name: 'gpt-35-turbo-16k'
    modelName: 'gpt-35-turbo-16k'
    version: '0613'
    sku: 'Standard'
    capacity: 60
  }
  {
    name: 'gpt-4'
    modelName: 'gpt-4'
    version: '0613'
    sku: 'Standard'
    capacity: 20
  }
  {
    name: 'gpt-4-32k'
    modelName: 'gpt-4-32k'
    version: '0613'
    sku: 'Standard'
    capacity: 20
  }
  {
    name: 'text-embedding-ada-002'
    modelName: 'text-embedding-ada-002'
    version: '2'
    sku: 'Standard'
    capacity: 60
  }
]

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module openAiService './modules/openAiService.bicep' = {
  name: 'openAiService'
  scope: rg
  dependsOn: [
    monitoring
  ]
  params: {
    location: location
    openAiServiceName: openAiServiceName
    openAiModeldeployments: openAiModelDeployments
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module aiSpeech './modules/aiSpeech.bicep' = {
  name: 'aiSpeech'
  scope: rg
  dependsOn: [
    monitoring
  ]
  params: {
    location: location
    aiSpeechName: aiSpeechName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module aiSearch './modules/aiSearch.bicep' = {
  name: 'aiSearch'
  scope: rg
  dependsOn: [
    monitoring
  ]
  params: {
    location: location
    aiSearchName: aiSearchName
    sku: 'basic'
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module aiContentSafety './modules/aiContentSafety.bicep' = {
  name: 'aiContentSafety'
  scope: rg
  dependsOn: [
    monitoring
  ]
  params: {
    location: location
    aiContentSafetyName: aiContentSafetyName
    sku: 'F0'
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module aiServices './modules/aiServices.bicep' = {
  name: 'aiServices'
  scope: rg
  dependsOn: [
    monitoring
  ]
  params: {
    location: aiServicesLocation // TODO: Update to location when available in Canada East
    aiServicesName: aiServicesName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module containerRegistry './modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    location: location
    containerRegistryName: containerRegistryName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: rg
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

module aiHub './modules/aiHub.bicep' = {
  name: 'aiHub'
  scope: rg
  dependsOn: [
    monitoring    
  ]
  params: {
    location: location
    aiHubName: aiHubName
    sku: 'Basic'
    storageAccountId: storageAccount.outputs.storageAccountId
    keyVaultId: keyVault.outputs.keyVaultId
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    containerRegistryId: containerRegistry.outputs.containerRegistryId
    openAiServiceName: openAiService.outputs.openAiServiceName
    aiSpeechName: aiSpeech.outputs.aiSpeechName
    aiContentSafetyName: aiContentSafety.outputs.aiContentSafetyName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

output openAiServiceEndpoint string = openAiService.outputs.openAiServiceEndpoint
