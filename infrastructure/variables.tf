variable "subscription_id" {
  description = "Azure subscription ID to deploy into. Leave empty to use the ARM_SUBSCRIPTION_ID env var or the az CLI default subscription."
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for all resources. Must support APIM v2, Microsoft Foundry (gpt-6.1-terra + text-embedding-3-small) and Azure Managed Redis."
  type        = string
  default     = "swedencentral"
}

variable "apim_location" {
  description = "Optional APIM region override when the main region lacks gateway capacity."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Short prefix used to name all resources (lowercase letters/numbers only)."
  type        = string
  default     = "aigw"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,8}$", var.name_prefix))
    error_message = "name_prefix must be 2-9 chars, lowercase letters/numbers, starting with a letter."
  }
}

variable "environment" {
  description = "Environment tag value (e.g. demo, dev)."
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Owner tag value (name or alias of the presenter)."
  type        = string
  default     = "unset"
}

variable "apim_publisher_name" {
  description = "Publisher name shown in the API Management developer portal."
  type        = string
  default     = "AI Gateway Demo"
}

variable "apim_publisher_email" {
  description = "Publisher email for the API Management instance (required by Azure)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.apim_publisher_email))
    error_message = "apim_publisher_email must be a valid email address."
  }
}

variable "apim_sku_name" {
  description = "API Management SKU. This lab validates PremiumV2_1; verify feature support when selecting another v2 tier."
  type        = string
  default     = "PremiumV2_1"

  validation {
    condition     = can(regex("^(BasicV2|StandardV2|PremiumV2)_[0-9]+$", var.apim_sku_name))
    error_message = "apim_sku_name must be a v2 SKU like BasicV2_1, StandardV2_1, or PremiumV2_1."
  }
}

variable "chat_model_name" {
  description = "Foundry chat model to deploy on both backends."
  type        = string
  default     = "gpt-6.1-terra"
}

variable "chat_model_version" {
  description = "Version of the chat model."
  type        = string
  default     = "2026-10-26"
}

variable "embedding_model_name" {
  description = "Foundry embedding model used by the semantic cache."
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_model_version" {
  description = "Version of the embedding model."
  type        = string
  default     = "1"
}

variable "chat_primary_tpm" {
  description = "Tokens-per-minute (thousands) capacity for the primary chat deployment."
  type        = number
  default     = 30
}

variable "chat_secondary_tpm" {
  description = "Tokens-per-minute (thousands) capacity for the secondary chat deployment (load-balance backend)."
  type        = number
  default     = 20
}

variable "embedding_tpm" {
  description = "Tokens-per-minute (thousands) capacity for the embedding deployment."
  type        = number
  default     = 30
}

variable "team_a_tokens_per_minute" {
  description = "TPM limit enforced by APIM for product dev-team-a (low tier). Kept small so the rate-limit demo triggers quickly."
  type        = number
  default     = 500
}

variable "team_a_token_quota" {
  description = "Daily token quota enforced by APIM for product dev-team-a."
  type        = number
  default     = 10000
}

variable "team_b_tokens_per_minute" {
  description = "TPM limit enforced by APIM for product dev-team-b (high tier)."
  type        = number
  default     = 5000
}

variable "content_safety_block_threshold" {
  description = "Severity threshold (0-7, EightSeverityLevels) at or above which Hate/Violence content is blocked by the llm-content-safety policy."
  type        = number
  default     = 4
}

variable "semantic_cache_score_threshold" {
  description = "Similarity (cosine distance) threshold for semantic cache lookups; higher = looser match. Evaluate the threshold against representative prompts; similarity does not guarantee answer correctness."
  type        = number
  default     = 0.2
}

variable "run_bootstrap_agent" {
  description = "Whether to run the post-apply bootstrap script that creates the demo Foundry agent and its initial tool."
  type        = bool
  default     = true
}

variable "deploy_grafana_dashboard" {
  description = "Whether to import the AI-gateway dashboard into Azure Managed Grafana via the post-apply script (requires az CLI + Grafana Admin on the instance)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
