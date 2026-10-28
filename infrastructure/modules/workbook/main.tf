resource "random_uuid" "workbook" {}

# Azure Monitor workbook - the AI gateway dashboard, linked to Application Insights.
resource "azurerm_application_insights_workbook" "this" {
  name                = random_uuid.workbook.result
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "AI Gateway - APIM + Foundry Dashboard"
  source_id           = lower(var.app_insights_id)
  data_json           = file("${path.module}/workbook.json")
  tags                = var.tags
}
