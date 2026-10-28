locals {
  api_path             = "openai"
  api_version_qs       = "2024-10-21"
  foundry_pool_backend = "foundry-pool"

  # Microsoft Learn MCP server, fronted by the gateway (MCP passthrough).
  mcp_api_path  = "ms-learn-mcp"
  learn_mcp_url = "https://learn.microsoft.com/api/mcp"
}

# ---------------------------------------------------------------------------
# API Management (v2 SKU) - the AI gateway. System-assigned identity is used for
# keyless authentication to the Foundry backends.
# ---------------------------------------------------------------------------
resource "azurerm_api_management" "this" {
  name                = "apim-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Observability: Application Insights logger + diagnostic (metrics enabled so
# the llm-emit-token-metric custom metrics flow to the workbook).
# ---------------------------------------------------------------------------
resource "azurerm_api_management_logger" "appinsights" {
  name                = "appinsights"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    connection_string = var.app_insights_connection_string
  }
}

resource "azapi_resource" "diagnostic" {
  type      = "Microsoft.ApiManagement/service/diagnostics@2024-05-01"
  name      = "applicationinsights"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      loggerId                = azurerm_api_management_logger.appinsights.id
      metrics                 = true
      alwaysLog               = "allErrors"
      verbosity               = "information"
      httpCorrelationProtocol = "W3C"
      sampling = {
        samplingType = "fixed"
        percentage   = 100
      }
      # Log the demo correlation headers so they land in App Insights request
      # customDimensions. This lets the workbook isolate a single test run by
      # the x-test-run-id the test harness stamps on every request (the fixed
      # APIM schema does NOT include arbitrary headers otherwise, so without this
      # every requests/dependencies panel goes blank when a Test Run ID is set).
      frontend = {
        request = {
          headers = ["x-test-run-id", "x-user-id"]
        }
      }
      backend = {
        request = {
          headers = ["x-test-run-id", "x-user-id"]
        }
      }
    }
  }
}

# APIM resource (gateway) logs -> Log Analytics, so ApiManagementGatewayLogs is queryable.
# "Dedicated" routes logs to the resource-specific ApiManagementGatewayLogs table
# (the table the workbook + runbook KQL query). Without it the default is the
# legacy "AzureDiagnostics" table, leaving those panels blank.
resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                           = "apim-to-law"
  target_resource_id             = azurerm_api_management.this.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "GatewayLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ---------------------------------------------------------------------------
# Redis external cache - backs the semantic cache policy.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_redis_cache" "this" {
  name              = "semantic-cache"
  api_management_id = azurerm_api_management.this.id
  connection_string = var.redis_connection_string
  redis_cache_id    = var.redis_cluster_id
  cache_location    = var.location
}

# ---------------------------------------------------------------------------
# Backends: two Foundry hosts (with circuit breakers), an embeddings backend
# for the semantic cache, and the Content Safety backend.
# ---------------------------------------------------------------------------
# The two Foundry hosts are created with azapi because the circuit-breaker
# config on a backend is only exposed by the preview management API, not the
# azurerm schema.
resource "azapi_resource" "foundry1" {
  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = "foundry-1"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      protocol = "http"
      url      = "${var.foundry_account1_openai_endpoint}/openai"
      circuitBreaker = {
        rules = [
          {
            name             = "foundry1-breaker"
            tripDuration     = "PT1M"
            acceptRetryAfter = true
            failureCondition = {
              count    = 3
              interval = "PT30S"
              statusCodeRanges = [
                { min = 429, max = 429 },
                { min = 500, max = 599 },
              ]
            }
          }
        ]
      }
    }
  }
}

resource "azapi_resource" "foundry2" {
  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = "foundry-2"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      protocol = "http"
      url      = "${var.foundry_account2_openai_endpoint}/openai"
      circuitBreaker = {
        rules = [
          {
            name             = "foundry2-breaker"
            tripDuration     = "PT1M"
            acceptRetryAfter = true
            failureCondition = {
              count    = 3
              interval = "PT30S"
              statusCodeRanges = [
                { min = 429, max = 429 },
                { min = 500, max = 599 },
              ]
            }
          }
        ]
      }
    }
  }
}

# The semantic-cache policy POSTs directly to this backend URL, so it must be the
# FULL embeddings endpoint (including /embeddings) per the APIM semantic-cache docs.
resource "azurerm_api_management_backend" "embeddings" {
  name                = "embeddings-backend"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  protocol            = "http"
  url                 = "${var.foundry_account1_openai_endpoint}/openai/deployments/${var.embedding_deployment_name}/embeddings"
}

resource "azapi_resource" "content_safety" {
  type                      = "Microsoft.ApiManagement/service/backends@2024-05-01"
  name                      = "content-safety-backend"
  parent_id                 = azurerm_api_management.this.id
  schema_validation_enabled = false

  body = {
    properties = {
      protocol = "http"
      url      = var.content_safety_endpoint
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.apim_content_safety]
}

resource "azurerm_role_assignment" "apim_content_safety" {
  scope                = var.content_safety_id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Microsoft Learn MCP - fronted by the gateway (MCP passthrough).
# The public, anonymous Microsoft Learn MCP server is exposed as an APIM MCP
# server (type = "mcp", streamable HTTP) so the demo agent's *tool* traffic is
# proxied/traced through APIM; agent model traffic goes directly to Foundry. The agent
# reaches it at  {gateway_url}/ms-learn-mcp  (no extra /mcp suffix - the backend
# URL already ends in /api/mcp). The API is anonymous (subscriptionRequired =
# false) so the agent tool is published INLINE (server_url only), which makes the
# tool card render in the Foundry portal Playground. Flip subscriptionRequired to
# true + add a Foundry project connection holding the subscription key for the
# governed (per-key rate-limit/quota) variant.
#
# Preview properties (type=mcp, backendId, mcpProperties) are only on the
# preview management API, so these are created with azapi.
# ---------------------------------------------------------------------------
resource "azapi_resource" "learn_mcp_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = "learn-mcp"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      protocol = "http"
      url      = local.learn_mcp_url
      type     = "Single"
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
}

resource "azapi_resource" "learn_mcp_api" {
  type      = "Microsoft.ApiManagement/service/apis@2024-06-01-preview"
  name      = local.mcp_api_path
  parent_id = azurerm_api_management.this.id

  # type=mcp / backendId / mcpProperties are preview-only properties not yet in
  # the azapi embedded schema, so skip client-side validation for this resource.
  schema_validation_enabled = false

  body = {
    properties = {
      type                 = "mcp"
      displayName          = "Microsoft Learn MCP"
      description          = "Microsoft Learn MCP server, fronted by the AI gateway (streamable HTTP)."
      path                 = local.mcp_api_path
      protocols            = ["https"]
      subscriptionRequired = false
      backendId            = azapi_resource.learn_mcp_backend.name
      mcpProperties = {
        transportType = "streamable"
      }
      subscriptionKeyParameterNames = {
        header = "api-key"
        query  = "subscription-key"
      }
    }
  }

  depends_on = [azapi_resource.learn_mcp_backend]
}

# Policy on the MCP passthrough: the Microsoft Learn streamable MCP server requires
# the request to accept BOTH application/json and text/event-stream. Force that
# Accept header on the backend request so the gateway-proxied call is not rejected
# with 406 Not Acceptable.
resource "azapi_resource" "learn_mcp_policy" {
  type      = "Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview"
  name      = "policy"
  parent_id = azapi_resource.learn_mcp_api.id

  body = {
    properties = {
      format = "xml"
      value  = replace(replace(file("${path.module}/../../policies/policy-mcp.xml"), "\r\n", "\n"), "\n", "\r\n")
    }
  }

  depends_on = [azapi_resource.learn_mcp_api]
}

# azapi because the Pool backend type is not yet in the azurerm schema.
resource "azapi_resource" "foundry_pool" {
  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = local.foundry_pool_backend
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      type = "Pool"
      pool = {
        services = [
          {
            id       = azapi_resource.foundry1.id
            priority = 1
            weight   = 50
          },
          {
            id       = azapi_resource.foundry2.id
            priority = 1
            weight   = 50
          }
        ]
      }
    }
  }

  depends_on = [
    azapi_resource.foundry1,
    azapi_resource.foundry2,
  ]
}

# ---------------------------------------------------------------------------
# The Foundry / LLM API and its operations.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api" "foundry" {
  name                  = "foundry-llm"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  revision              = "1"
  display_name          = "Foundry LLM API"
  description           = "Azure OpenAI-compatible Foundry inference API, governed by the AI gateway."
  path                  = local.api_path
  protocols             = ["https"]
  subscription_required = true

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }
}

resource "azurerm_api_management_api_operation" "chat_completions" {
  operation_id        = "chat-completions"
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Chat Completions"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/chat/completions"
  description         = "Creates a chat completion."

  template_parameter {
    name     = "deployment-id"
    type     = "string"
    required = true
  }
}

resource "azurerm_api_management_api_operation" "embeddings" {
  operation_id        = "embeddings"
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Embeddings"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/embeddings"
  description         = "Creates an embedding vector."

  template_parameter {
    name     = "deployment-id"
    type     = "string"
    required = true
  }
}

# ---------------------------------------------------------------------------
# API-scope policy (content safety + semantic cache + MI auth + token metrics).
# ---------------------------------------------------------------------------
resource "azurerm_api_management_api_policy" "foundry" {
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = templatefile("${path.module}/../../policies/policy-api.xml", {
    content_safety_threshold       = var.content_safety_block_threshold
    semantic_cache_score_threshold = var.semantic_cache_score_threshold
  })

  depends_on = [
    azapi_resource.foundry_pool,
    azurerm_api_management_backend.embeddings,
    azapi_resource.content_safety,
    azapi_resource.diagnostic,
  ]
}

# ---------------------------------------------------------------------------
# Products (per-team quotas) + subscriptions.
# ---------------------------------------------------------------------------
resource "azurerm_api_management_product" "team_a" {
  product_id            = "dev-team-a"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Dev Team A (low tier)"
  description           = "Low token rate limit and a daily quota - used to demo throttling (429) and quota (403)."
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product" "team_b" {
  product_id            = "dev-team-b"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Dev Team B (high tier)"
  description           = "Higher token rate limit and no daily quota."
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "team_a" {
  product_id          = azurerm_api_management_product.team_a.product_id
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_api" "team_b" {
  product_id          = azurerm_api_management_product.team_b.product_id
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_policy" "team_a" {
  product_id          = azurerm_api_management_product.team_a.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = templatefile("${path.module}/../../policies/policy-product-low.xml", {
    tokens_per_minute = var.team_a_tokens_per_minute
    token_quota       = var.team_a_token_quota
  })
}

resource "azurerm_api_management_product_policy" "team_b" {
  product_id          = azurerm_api_management_product.team_b.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = templatefile("${path.module}/../../policies/policy-product-high.xml", {
    tokens_per_minute = var.team_b_tokens_per_minute
  })
}

resource "azurerm_api_management_subscription" "team_a" {
  display_name        = "dev-team-a-subscription"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.team_a.id
  state               = "active"
  allow_tracing       = false
}

resource "azurerm_api_management_subscription" "team_b" {
  display_name        = "dev-team-b-subscription"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.team_b.id
  state               = "active"
  allow_tracing       = false
}

# ---------------------------------------------------------------------------
# RBAC: let the APIM managed identity call the Foundry backends keylessly.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "apim_openai_account1" {
  scope                = var.foundry_account1_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "apim_openai_account2" {
  scope                = var.foundry_account2_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}
