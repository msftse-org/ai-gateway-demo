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

variable "chat_model_name" {
  type        = string
  description = "Chat model name."
}

variable "chat_model_version" {
  type        = string
  description = "Chat model version."
}

variable "embedding_model_name" {
  type        = string
  description = "Embedding model name."
}

variable "embedding_model_version" {
  type        = string
  description = "Embedding model version."
}

variable "chat_primary_tpm" {
  type        = number
  description = "Capacity (thousand TPM) for the primary chat deployment."
}

variable "chat_secondary_tpm" {
  type        = number
  description = "Capacity (thousand TPM) for the secondary chat deployment."
}

variable "embedding_tpm" {
  type        = number
  description = "Capacity (thousand TPM) for the embedding deployment."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}

variable "app_insights_id" {
  type        = string
  description = "Resource ID of the Application Insights instance to link the Foundry accounts to (tracing/observability)."
}

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string used as the credential for the Foundry App Insights connection."
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace that receives the Foundry account diagnostic logs and metrics."
}
