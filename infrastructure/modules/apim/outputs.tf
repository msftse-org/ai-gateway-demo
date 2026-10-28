output "apim_id" {
  description = "Resource ID of the API Management instance."
  value       = azurerm_api_management.this.id
}

output "apim_name" {
  description = "Name of the API Management instance."
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "Gateway URL of the API Management instance."
  value       = azurerm_api_management.this.gateway_url
}

output "principal_id" {
  description = "Managed identity principal ID of the API Management instance."
  value       = azurerm_api_management.this.identity[0].principal_id
}

output "api_path" {
  description = "Base path of the Foundry LLM API."
  value       = local.api_path
}

output "team_a_subscription_key" {
  description = "Primary subscription key for product dev-team-a (low tier)."
  value       = azurerm_api_management_subscription.team_a.primary_key
  sensitive   = true
}

output "team_b_subscription_key" {
  description = "Primary subscription key for product dev-team-b (high tier)."
  value       = azurerm_api_management_subscription.team_b.primary_key
  sensitive   = true
}

output "mcp_server_url" {
  description = "Streamable-HTTP endpoint of the Microsoft Learn MCP server, fronted by the gateway (for the agent's MCP tool)."
  value       = "${azurerm_api_management.this.gateway_url}/${local.mcp_api_path}"
}
