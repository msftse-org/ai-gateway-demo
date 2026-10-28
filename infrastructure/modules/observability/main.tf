# Log Analytics workspace - backing store for App Insights, APIM diagnostics and workbook KQL.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Workspace-based Application Insights - destination for APIM LLM logs and token metrics.
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}
