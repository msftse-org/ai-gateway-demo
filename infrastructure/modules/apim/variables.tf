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

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "publisher_name" {
  type        = string
  description = "APIM publisher name."
}

variable "publisher_email" {
  type        = string
  description = "APIM publisher email."
}

variable "sku_name" {
  type        = string
  description = "APIM v2 SKU name (e.g. PremiumV2_1)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}

variable "app_insights_id" {
  type        = string
  description = "Application Insights resource ID."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace resource ID for APIM resource (gateway) logs."
}

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string."
  sensitive   = true
}

# --- Foundry backends ---
variable "foundry_account1_id" {
  type        = string
  description = "Resource ID of Foundry account 1 (for RBAC)."
}

variable "foundry_account2_id" {
  type        = string
  description = "Resource ID of Foundry account 2 (for RBAC)."
}

variable "foundry_account1_openai_endpoint" {
  type        = string
  description = "Azure OpenAI-compatible endpoint base for account 1."
}

variable "foundry_account2_openai_endpoint" {
  type        = string
  description = "Azure OpenAI-compatible endpoint base for account 2."
}

variable "embedding_deployment_name" {
  type        = string
  description = "Embedding deployment name (for the semantic-cache embeddings backend)."
}

# --- Content safety backend ---
variable "content_safety_endpoint" {
  type        = string
  description = "Content Safety endpoint."
}

variable "content_safety_id" {
  type        = string
  description = "Content Safety resource ID for the gateway managed identity role assignment."
}

# --- Redis external cache ---
variable "redis_cluster_id" {
  type        = string
  description = "Resource ID of the Redis cluster."
}

variable "redis_connection_string" {
  type        = string
  description = "Redis connection string for the APIM external cache."
  sensitive   = true
}

# --- Policy template values ---
variable "semantic_cache_score_threshold" {
  type        = number
  description = "Semantic cache similarity score threshold."
}

variable "content_safety_block_threshold" {
  type        = number
  description = "Content safety block severity threshold."
}

variable "team_a_tokens_per_minute" {
  type        = number
  description = "TPM limit for product dev-team-a."
}

variable "team_a_token_quota" {
  type        = number
  description = "Daily token quota for product dev-team-a."
}

variable "team_b_tokens_per_minute" {
  type        = number
  description = "TPM limit for product dev-team-b."
}
