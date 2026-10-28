locals {
  suffix = random_string.suffix.result

  base_tags = merge({
    Project     = "apim-ai-gateway-demo"
    Environment = var.environment
    Owner       = var.owner
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}-${var.environment}"
  location = var.location
  tags     = local.base_tags
}

module "observability" {
  source = "./modules/observability"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.base_tags
}

module "redis" {
  source = "./modules/redis"

  name_prefix       = var.name_prefix
  suffix            = local.suffix
  location          = var.location
  resource_group_id = azurerm_resource_group.this.id
  tags              = local.base_tags
}

module "content_safety" {
  source = "./modules/content-safety"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.base_tags
}

module "foundry" {
  source = "./modules/foundry"

  name_prefix             = var.name_prefix
  suffix                  = local.suffix
  location                = var.location
  resource_group_id       = azurerm_resource_group.this.id
  chat_model_name         = var.chat_model_name
  chat_model_version      = var.chat_model_version
  embedding_model_name    = var.embedding_model_name
  embedding_model_version = var.embedding_model_version
  chat_primary_tpm        = var.chat_primary_tpm
  chat_secondary_tpm      = var.chat_secondary_tpm
  embedding_tpm           = var.embedding_tpm
  tags                    = local.base_tags

  app_insights_id                = module.observability.app_insights_id
  app_insights_connection_string = module.observability.app_insights_connection_string
  log_analytics_workspace_id     = module.observability.log_analytics_workspace_id
}

module "apim" {
  source = "./modules/apim"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = var.apim_location != "" ? var.apim_location : var.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
  tags                = local.base_tags

  app_insights_id                = module.observability.app_insights_id
  app_insights_connection_string = module.observability.app_insights_connection_string
  log_analytics_workspace_id     = module.observability.log_analytics_workspace_id

  foundry_account1_id              = module.foundry.account1_id
  foundry_account2_id              = module.foundry.account2_id
  foundry_account1_openai_endpoint = module.foundry.account1_openai_endpoint
  foundry_account2_openai_endpoint = module.foundry.account2_openai_endpoint
  embedding_deployment_name        = module.foundry.embedding_deployment_name

  content_safety_endpoint = module.content_safety.endpoint
  content_safety_id       = module.content_safety.id

  redis_cluster_id        = module.redis.cluster_id
  redis_connection_string = module.redis.connection_string

  semantic_cache_score_threshold = var.semantic_cache_score_threshold
  content_safety_block_threshold = var.content_safety_block_threshold
  team_a_tokens_per_minute       = var.team_a_tokens_per_minute
  team_a_token_quota             = var.team_a_token_quota
  team_b_tokens_per_minute       = var.team_b_tokens_per_minute
}

module "workbook" {
  source = "./modules/workbook"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  app_insights_id     = module.observability.app_insights_id
  tags                = local.base_tags
}

module "grafana" {
  source = "./modules/grafana"

  name_prefix                = var.name_prefix
  suffix                     = local.suffix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  resource_group_id          = azurerm_resource_group.this.id
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  deploy_dashboard           = var.deploy_grafana_dashboard
  tags                       = local.base_tags
}

# Post-apply: create the demo Foundry agent (agent-aigw-demo) and its initial tool,
# routing its Microsoft Learn tool through APIM; its model uses Foundry directly.

resource "terraform_data" "bootstrap_agent" {
  count = var.run_bootstrap_agent ? 1 : 0

  triggers_replace = [
    module.foundry.project_id,
    module.apim.apim_id,
    module.foundry.chat_deployment_name,
    var.chat_model_version,
    filesha256("${path.root}/../scripts/bootstrap-agent.py"),
  ]

  provisioner "local-exec" {
    command     = "python3 ${path.root}/../scripts/bootstrap-agent.py"
    working_dir = path.root

    environment = {
      PROJECT_ENDPOINT      = module.foundry.project_endpoint
      APIM_GATEWAY_URL      = module.apim.gateway_url
      APIM_API_PATH         = module.apim.api_path
      APIM_SUBSCRIPTION_KEY = nonsensitive(module.apim.team_b_subscription_key)
      CHAT_DEPLOYMENT       = module.foundry.chat_deployment_name
      AGENT_NAME            = "agent-aigw-demo"
      MCP_SERVER_URL        = module.apim.mcp_server_url
      MCP_SERVER_LABEL      = "microsoft_learn"
      BOOTSTRAP_OUT         = "${path.root}/../.bootstrap/agent.json"
    }
  }

  depends_on = [
    module.apim,
    module.foundry,
  ]
}
