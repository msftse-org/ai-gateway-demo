variable "name_prefix" {
  type        = string
  description = "Resource name prefix."
}

variable "suffix" {
  type        = string
  description = "Unique suffix for globally unique names."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the parent resource group (parent_id for azapi)."
}

variable "sku_name" {
  type        = string
  description = "Azure Managed Redis SKU (e.g. Balanced_B1)."
  default     = "Balanced_B1"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
