variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
}

variable "suffix" {
  description = "Unique suffix for globally/regionally unique names."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create resources in."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
