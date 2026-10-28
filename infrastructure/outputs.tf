output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Main region for models and supporting services; APIM may use its own region override."
  value       = var.location
}

output "apim_gateway_url" {
  description = "API Management gateway URL for the model API and MCP proxy; agent model calls use Foundry directly."
  value       = module.apim.gateway_url
}

output "apim_name" {
  description = "API Management instance name."
  value       = module.apim.apim_name
}

output "api_path" {
  description = "Base path of the Foundry LLM API on the gateway."
  value       = module.apim.api_path
}

output "chat_deployment_name" {
  description = "Chat model deployment name (use as {deployment-id} in the URL)."
  value       = module.foundry.chat_deployment_name
}

output "embedding_deployment_name" {
  description = "Embedding model deployment name."
  value       = module.foundry.embedding_deployment_name
}

output "team_a_subscription_key" {
  description = "APIM subscription key for product dev-team-a (low tier)."
  value       = module.apim.team_a_subscription_key
  sensitive   = true
}

output "team_b_subscription_key" {
  description = "APIM subscription key for product dev-team-b (high tier)."
  value       = module.apim.team_b_subscription_key
  sensitive   = true
}

output "mcp_server_url" {
  description = "Microsoft Learn MCP endpoint fronted by the gateway (used by the agent's MCP tool)."
  value       = module.apim.mcp_server_url
}

output "app_insights_connection_string" {
  description = "Application Insights connection string."
  value       = module.observability.app_insights_connection_string
  sensitive   = true
}

output "foundry_project_endpoint" {
  description = "AIProjectClient endpoint for the demo project."
  value       = module.foundry.project_endpoint
}

output "foundry_project_name" {
  description = "Demo Foundry project name."
  value       = module.foundry.project_name
}

output "agent_name" {
  description = "Name of the demo agent created by the bootstrap script."
  value       = var.run_bootstrap_agent ? "agent-aigw-demo" : "(bootstrap disabled)"
}

output "agent_info_file" {
  description = "Path to the JSON file the bootstrap script writes with the agent ID and details."
  value       = "${path.root}/../.bootstrap/agent.json"
}

output "workbook_id" {
  description = "Resource ID of the Azure Monitor workbook dashboard."
  value       = module.workbook.workbook_id
}

output "workbook_portal_url" {
  description = "Direct portal URL to open the workbook dashboard."
  value       = "https://portal.azure.com/#@/resource${module.workbook.workbook_id}/workbook"
}

output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint."
  value       = module.grafana.grafana_endpoint
}

output "grafana_dashboard_url" {
  description = "Direct URL to the AI Gateway dashboard in Azure Managed Grafana."
  value       = module.grafana.dashboard_url
}
