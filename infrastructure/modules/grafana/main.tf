data "azurerm_client_config" "current" {}

locals {
  # Stable UID embedded in dashboard.json; used to build the direct dashboard URL.
  dashboard_uid = "aigw-ai-gateway"
}

# Azure Managed Grafana - hosted Grafana with the Azure Monitor data source
# pre-installed, used to query the App Insights / Log Analytics workspace.
resource "azurerm_dashboard_grafana" "this" {
  name                              = "graf-${var.name_prefix}-${var.suffix}"
  resource_group_name               = var.resource_group_name
  location                          = var.location
  sku                               = "Standard"
  grafana_major_version             = var.grafana_major_version
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  tags                              = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Let Grafana's managed identity read all monitoring data (metrics + Log
# Analytics logs) in the resource group so its Azure Monitor data source works.
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = var.resource_group_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

# Grant the deployer the Grafana Admin data-plane role so the import script can
# publish the dashboard (and so the human can edit it in the portal).
resource "azurerm_role_assignment" "deployer_grafana_admin" {
  scope                = azurerm_dashboard_grafana.this.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Post-apply: import the AI-gateway dashboard via the Grafana data-plane API.
resource "terraform_data" "import_dashboard" {
  count = var.deploy_dashboard ? 1 : 0

  triggers_replace = [
    azurerm_dashboard_grafana.this.id,
    filesha256("${path.module}/dashboard.json"),
    var.log_analytics_workspace_id,
  ]

  provisioner "local-exec" {
    command = "python3 ${path.module}/import-dashboard.py"

    environment = {
      GRAFANA_URL    = azurerm_dashboard_grafana.this.endpoint
      WORKSPACE_ID   = var.log_analytics_workspace_id
      DASHBOARD_PATH = "${path.module}/dashboard.json"
    }
  }

  depends_on = [
    azurerm_role_assignment.grafana_monitoring_reader,
    azurerm_role_assignment.deployer_grafana_admin,
  ]
}
