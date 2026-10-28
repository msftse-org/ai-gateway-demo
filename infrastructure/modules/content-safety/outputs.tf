output "id" {
  description = "Resource ID of the Content Safety account."
  value       = azurerm_cognitive_account.this.id
}

output "name" {
  description = "Name of the Content Safety account."
  value       = azurerm_cognitive_account.this.name
}

output "endpoint" {
  description = "Endpoint of the Content Safety account (used as the APIM content-safety backend URL)."
  value       = azurerm_cognitive_account.this.endpoint
}
