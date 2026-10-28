variable "name_prefix" {
  type        = string
  description = "Resource name prefix."
}

variable "suffix" {
  type        = string
  description = "Unique suffix."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "app_insights_id" {
  type        = string
  description = "Application Insights resource ID the workbook is linked to."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
