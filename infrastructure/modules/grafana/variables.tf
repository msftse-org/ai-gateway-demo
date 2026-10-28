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

variable "resource_group_id" {
  type        = string
  description = "Resource group ID; scope for the Grafana identity's Monitoring Reader role."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace resource ID the dashboard queries (App Insights workspace-based store)."
}

variable "grafana_major_version" {
  type        = string
  description = "Azure Managed Grafana major version."
  default     = "12"
}

variable "deploy_dashboard" {
  type        = bool
  description = "Whether to import the AI-gateway dashboard via the post-apply script."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
