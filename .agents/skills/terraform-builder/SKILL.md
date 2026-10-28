---
name: terraform-builder
description: 'Design and build production-grade Terraform configurations for Azure. Use when: Terraform, infrastructure as code, IaC, Azure infrastructure, create Terraform modules, provision Azure resources, Terraform best practices, Azure best practices, deploy infrastructure, HCL code'
argument-hint: 'Describe the Azure infrastructure you want to provision'
---

# Terraform Master Builder

Expert-level Terraform and Azure cloud infrastructure skill. Designs, creates, and maintains production-grade Terraform configurations following both Terraform and Azure best practices.

## When to Use

- Creating new Terraform modules for Azure resources
- Scaffolding IaC folder structure
- Reviewing or refactoring existing Terraform code
- Applying Terraform and Azure best practices
- Deploying Azure infrastructure with proper state management

## File Structure Rules

**ALL Terraform files MUST be created under the `infrastructure/` folder in the workspace root.** Never create `.tf` files outside of `infrastructure/`.

Use this exact folder structure:

```
infrastructure/
├── main.tf              # Root module — calls child modules from infrastructure/modules/
├── variables.tf         # Input variables for the root module
├── outputs.tf           # Outputs from the root module
├── providers.tf         # Provider configuration (azurerm, azuread, etc.)
├── backend.tf           # Optional: remote state backend configuration (only when requested)
├── terraform.tfvars     # Default variable values (if needed)
└── modules/
    └── <module-name>/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

- The root `infrastructure/main.tf` MUST reference modules using relative paths: `source = "./modules/<module-name>"`
- Each logical resource grouping gets its own module under `infrastructure/modules/`
- Never use absolute paths in module sources

## Terraform Best Practices

- **State management**: Use local state by default. Add `backend.tf` and remote state configuration (Azure Storage backend) only when the user explicitly requests remote state
- **Variables**: Every configurable value must be a variable with a description and type. Use `validation` blocks where appropriate
- **Naming**: Use snake_case for all resource names and variables. Use descriptive, consistent naming conventions
- **Versioning**: Pin provider versions in `providers.tf` using `~>` constraints
- **Formatting**: All code must be properly formatted (`terraform fmt` compliant)
- **Modules**: Keep modules small and focused on a single concern. Each module should be independently reusable
- **Data sources**: Prefer data sources over hardcoded IDs for referencing existing resources
- **Locals**: Use `locals` blocks to reduce repetition and improve readability
- **Outputs**: Expose useful attributes from every module (IDs, names, endpoints)
- **Tags**: Apply consistent tags to all resources using a shared `tags` variable merged with resource-specific tags
- **Sensitive values**: Mark sensitive variables and outputs with `sensitive = true`

## Azure Best Practices

- **Microsoft Learn MCP grounding**: Use Microsoft Learn MCP to validate resource creation patterns and Azure best practices before generating Terraform changes
- **Resource naming**: Follow Azure naming conventions (e.g., `rg-`, `st`, `vnet-`, `kv-` prefixes)
- **Resource groups**: Group related resources logically; one resource group per environment or application boundary
- **Regions**: Parameterize location — never hardcode Azure regions
- **Networking**: Use Network Security Groups, private endpoints, and service endpoints where applicable
- **Identity**: Prefer Managed Identities over service principals or keys
- **Key Vault**: Store secrets in Azure Key Vault, reference them via data sources
- **Diagnostics**: Enable diagnostic settings and logging for all supported resources
- **SKU selection**: Parameterize SKUs and tiers to support different environments (dev/staging/prod)
- **Locks**: Consider resource locks for production-critical resources

## Constraints

- DO NOT create Terraform files outside the `infrastructure/` folder
- DO NOT hardcode secrets, passwords, or subscription IDs in any `.tf` file
- DO NOT use deprecated Terraform syntax or provider features
- DO NOT create monolithic modules — split by resource concern
- DO NOT skip variable descriptions or type declarations
- DO NOT create `backend.tf` unless the user explicitly asks for remote state
- ALWAYS create modules under `infrastructure/modules/` and reference them from `infrastructure/main.tf`

## Procedure

1. Understand the user's infrastructure requirements and whether they explicitly want remote state
2. Use Microsoft Learn MCP to ground implementation details:
    - Run `microsoft_docs_search` for the target Azure resources and best practices
    - Run `microsoft_code_sample_search` for Terraform-related Azure examples when needed
    - Run `microsoft_docs_fetch` for full guidance on selected Microsoft Learn pages when deeper detail is needed
3. Plan the module structure and identify which modules are needed
4. Create the module files under `infrastructure/modules/<module-name>/`
5. Create or update the root `infrastructure/main.tf` to reference all modules
6. Create or update `infrastructure/variables.tf`, `infrastructure/outputs.tf`, and `infrastructure/providers.tf`
7. Only if the user requested remote state, create or update `infrastructure/backend.tf`; otherwise keep local state
8. Validate the configuration by running `terraform fmt -check` and `terraform validate` when possible
9. Explain the module structure, state approach (local vs remote), and summarize what was created
10. Invoke the `documentation-keeper` skill to update `AGENT.md` and `README.md` with the infrastructure changes (new modules, variables, outputs, decisions, project structure)
