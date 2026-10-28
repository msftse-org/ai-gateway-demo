locals {
  account1_subdomain = "ai-${var.name_prefix}-1-${var.suffix}"
  account2_subdomain = "ai-${var.name_prefix}-2-${var.suffix}"
  project_name       = "proj-${var.name_prefix}"
}

# ---------------------------------------------------------------------------
# Foundry account 1 - hosts the primary chat deployment, the embedding model,
# and the demo project/agent. Created with azapi to enable project management.
# ---------------------------------------------------------------------------
resource "azapi_resource" "account1" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = local.account1_subdomain
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = local.account1_subdomain
      publicNetworkAccess    = "Enabled"
      disableLocalAuth       = true
    }
  }

  response_export_values = ["identity.principalId", "properties.endpoint"]
}

# Foundry account 2 - second backend host for the load-balancer / failover demo.
resource "azapi_resource" "account2" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = local.account2_subdomain
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      allowProjectManagement = false
      customSubDomainName    = local.account2_subdomain
      publicNetworkAccess    = "Enabled"
      disableLocalAuth       = true
    }
  }

  response_export_values = ["identity.principalId", "properties.endpoint"]
}

# Demo project on account 1 - container for the agent created by the bootstrap script.
resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = local.project_name
  parent_id = azapi_resource.account1.id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "AI Gateway Demo"
      description = "Demo project for the APIM AI gateway session."
    }
  }

  response_export_values = ["identity.principalId"]

  depends_on = [
    azurerm_cognitive_deployment.chat_primary,
    azurerm_cognitive_deployment.embedding,
    azapi_resource.account1_appinsights,
  ]
}

# ---------------------------------------------------------------------------
# Model deployments (azurerm) on the accounts above.
# ---------------------------------------------------------------------------
resource "azurerm_cognitive_deployment" "chat_primary" {
  lifecycle {
    create_before_destroy = true
  }

  name                 = var.chat_model_name
  cognitive_account_id = azapi_resource.account1.id

  model {
    format  = "OpenAI"
    name    = var.chat_model_name
    version = var.chat_model_version
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_primary_tpm
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = var.embedding_model_name
  cognitive_account_id = azapi_resource.account1.id

  model {
    format  = "OpenAI"
    name    = var.embedding_model_name
    version = var.embedding_model_version
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.embedding_tpm
  }
}

resource "azurerm_cognitive_deployment" "chat_secondary" {
  lifecycle {
    create_before_destroy = true
  }

  name                 = var.chat_model_name
  cognitive_account_id = azapi_resource.account2.id

  model {
    format  = "OpenAI"
    name    = var.chat_model_name
    version = var.chat_model_version
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_secondary_tpm
  }
}

# ---------------------------------------------------------------------------
# Observability wiring for the Foundry accounts.
#   1. Application Insights connection on each account so Foundry tracing
#      (agents, evaluations) and OpenTelemetry data flow into the shared
#      Application Insights instance.
#   2. Diagnostic settings routing each account's platform logs + metrics to
#      the Log Analytics workspace.
# ---------------------------------------------------------------------------

# Application Insights connection - account 1 (hosts the project + agents).
# Only account 1 has allowProjectManagement = true, so only it can host
# connections. Account 2 is a backend-only model host (no project/agents/traces)
# and the connections API rejects it ("Unable to find workspace"); account 2 is
# instead covered by its diagnostic setting below.
resource "azapi_resource" "account1_appinsights" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name      = "appinsights"
  parent_id = azapi_resource.account1.id

  body = {
    properties = {
      category      = "AppInsights"
      target        = var.app_insights_id
      authType      = "ApiKey"
      isSharedToAll = true
      credentials = {
        key = var.app_insights_connection_string
      }
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.app_insights_id
      }
    }
  }
}

# Discover the supported log categories per account (varies by region/kind).
data "azurerm_monitor_diagnostic_categories" "account1" {
  resource_id = azapi_resource.account1.id
}

data "azurerm_monitor_diagnostic_categories" "account2" {
  resource_id = azapi_resource.account2.id
}

# Diagnostic settings - account 1 logs + metrics to Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "account1" {
  name                       = "foundry-to-law"
  target_resource_id         = azapi_resource.account1.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.account1.log_category_types
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings - account 2 logs + metrics to Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "account2" {
  name                       = "foundry-to-law"
  target_resource_id         = azapi_resource.account2.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.account2.log_category_types
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
