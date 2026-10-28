output "account1_id" {
  description = "Resource ID of Foundry account 1 (primary)."
  value       = azapi_resource.account1.id
}

output "account2_id" {
  description = "Resource ID of Foundry account 2 (secondary backend)."
  value       = azapi_resource.account2.id
}

output "account1_principal_id" {
  description = "System-assigned managed identity principal ID of account 1."
  value       = azapi_resource.account1.output.identity.principalId
}

output "account1_openai_endpoint" {
  description = "Azure OpenAI-compatible endpoint base for account 1 (primary backend)."
  value       = "https://${local.account1_subdomain}.openai.azure.com"
}

output "account2_openai_endpoint" {
  description = "Azure OpenAI-compatible endpoint base for account 2 (secondary backend)."
  value       = "https://${local.account2_subdomain}.openai.azure.com"
}

output "account1_cognitiveservices_endpoint" {
  description = "Cognitive Services endpoint for account 1 (used for embeddings backend)."
  value       = azapi_resource.account1.output.properties.endpoint
}

output "project_id" {
  description = "Resource ID of the demo Foundry project."
  value       = azapi_resource.project.id
}

output "project_name" {
  description = "Name of the demo Foundry project."
  value       = local.project_name
}

output "project_endpoint" {
  description = "AIProjectClient endpoint for the demo project (used by the bootstrap script and agent client)."
  value       = "https://${local.account1_subdomain}.services.ai.azure.com/api/projects/${local.project_name}"
}

output "chat_deployment_name" {
  description = "Name of the chat model deployment (same on both accounts)."
  value       = azurerm_cognitive_deployment.chat_primary.name
}

output "embedding_deployment_name" {
  description = "Name of the embedding model deployment."
  value       = azurerm_cognitive_deployment.embedding.name
}
