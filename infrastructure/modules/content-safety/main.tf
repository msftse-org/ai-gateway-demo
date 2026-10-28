# Azure AI Content Safety account - backend for the APIM llm-content-safety policy.
# APIM authenticates to it with its managed identity (Cognitive Services User role granted in the apim module).
resource "azurerm_cognitive_account" "this" {
  name                  = "cs-${var.name_prefix}-${var.suffix}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "ContentSafety"
  sku_name              = "S0"
  local_auth_enabled    = false
  custom_subdomain_name = "cs-${var.name_prefix}-${var.suffix}"
  tags                  = var.tags
}
