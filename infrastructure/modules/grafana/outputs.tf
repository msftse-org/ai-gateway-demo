output "grafana_id" {
  description = "Resource ID of the Azure Managed Grafana instance."
  value       = azurerm_dashboard_grafana.this.id
}

output "grafana_name" {
  description = "Name of the Azure Managed Grafana instance."
  value       = azurerm_dashboard_grafana.this.name
}

output "grafana_endpoint" {
  description = "Public endpoint of the Azure Managed Grafana instance."
  value       = azurerm_dashboard_grafana.this.endpoint
}

output "dashboard_url" {
  description = "Direct URL to the AI Gateway dashboard."
  value       = "${azurerm_dashboard_grafana.this.endpoint}/d/${local.dashboard_uid}"
}
