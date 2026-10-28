output "workbook_id" {
  description = "Resource ID of the Azure Monitor workbook."
  value       = azurerm_application_insights_workbook.this.id
}

output "workbook_name" {
  description = "Name (GUID) of the workbook."
  value       = azurerm_application_insights_workbook.this.name
}
