# Azure AI Gateway Demo — implementation notes

Customer-neutral Terraform lab with model gateway policies, two Foundry chat backends, a prompt agent with a gateway-proxied Microsoft Learn tool, and monitoring dashboards.

## Architecture decisions

- Keep all Terraform in `infrastructure/`, split by reusable module; local state is the default.
- Parameterize naming, publisher, subscription, regions, model capacities and team limits. Never commit deployment-specific tfvars or generated secrets/state.
- Managed identity authenticates APIM to Foundry and Content Safety. Local Cognitive Services authentication is disabled.
- Model clients use the `/openai` policy path. The prompt agent uses its Foundry model directly and only its MCP tool is proxied through `/ms-learn-mcp`.
- Equal-priority, equal-weight backend pool demonstrates balancing. Circuit breakers and retries require separate failure testing.
- Product-scope limits use actual token usage. Cache entries vary by APIM subscription and deployment; TTL is 120 seconds.
- Query request correlation via `Request-x-test-run-id`; token metrics use `Test Run ID`. Dependencies do not reliably carry frontend request headers. Dedicated gateway logs use `ApiManagementGatewayLogs`.
- Preserve the configured module topology during generalization. Production networking and additional services are separate design work.

## Project structure

```text
infrastructure/          Terraform root, reusable modules and policy XML
  modules/              apim, foundry, redis, content-safety,
                        observability, workbook, grafana
  policies/             Model API, team limits and MCP policy
clients/                Shared client helpers and six scenarios
scripts/                Portable lab entry point, agent bootstrap,
                        MCP configuration and local settings export
docs/runbook/           Presenter walkthrough and portal navigation
docs/diagrams/          Resource architecture and agent-flow PNGs
docs/architecture-guide.html  Standalone offline customer guide
AGENT.md                Implementation notes and changelog
NOTICE.md               Source provenance
```

## Validation conventions

Run Terraform format/validate before deployment. Use the committed provider lockfile. Run all six scenarios after provisioning; do not equate an infrastructure apply with a functioning agent or imported dashboard. Keep validation artifacts outside tracked source. Preserve local state until successful teardown.

## Changelog

### 2026-10-25 — Customer-neutral initial snapshot
- Created a new repository snapshot from the source and verified deployment adaptations; provenance is recorded separately in NOTICE.md.
- Removed customer-specific names and environment identifiers from source and examples.
- Added a portable deployment/test entry point and committed provider lockfile.
- Preserved keyless backends, optional APIM region override, sequenced Foundry project creation, equal-priority backend pool and local client settings exporter.
- Corrected model-versus-tool routing explanations and strengthened semantic-cache validation to require successful responses with nonempty IDs.
- Supplied a demo threshold in the example configuration and documented the current validation boundaries.

### 2026-10-25 — Portable presenter workflow
- Aligned prerequisite, configuration-export and cleanup instructions with the repository-local virtual environment and lab wrapper.
- Made help available without Azure authentication; cleanup instructions use this checkout’s recorded state and resource-group output.
- Clarified Terraform output descriptions for the APIM region override and direct agent model path.

### 2026-10-25 — Replacement deployment validation
- Deployed all 52 managed objects from the generic configuration and verified all six runtime scenarios.
- Cache replay required successful responses with complete matching IDs; balancing observed both hosts.
- Verified the 28-panel Grafana dashboard and a no-change Terraform apply.
- Normalize MCP policy line endings at the Terraform boundary to match Azure and prevent platform-dependent cosmetic drift.

### 2026-10-28 — Upgrade the chat model
- Default both chat backends to GA `gpt-6.1-terra` version `2026-10-26`, verified in the live Sweden Central catalog and subscription quota.
- Create replacement deployments before deleting old deployments; recreate the agent version when its model, model version or bootstrap code changes.
- Use `max_completion_tokens` and `reasoning_effort=none` for short gateway demos. The agent continues using Responses with MCP.
- Partition the semantic cache by deployment as well as subscription; verify the returned model in basic chat and require actual MCP execution in scenario 06.
- Document the portal request and remove obsolete price assumptions from both dashboards; presenters must configure their Azure rates.
- Preserve the live disabled legacy subscription tracing setting during the model upgrade; portal tracing uses the current API-scoped workflow.
- Validation: Terraform format/validate passed; applied upgrade; both deployments report Succeeded; agent version 2 updated; all six live scenarios passed; exact portal request returned the new model; Grafana returned HTTP 200 with 28 panels; final Terraform plan has no changes.

### 2026-10-28 — Customer architecture documentation
- Added resource and agent-flow diagrams prominently to the README, plus an offline HTML architecture guide for architects and engineers.
- Documented deployed resources, model-versus-tool policy boundaries, identity, portal requests, dated validation evidence and production design questions.
- Created the public msftse-org/ai-gateway-demo documentation repository through repository-factory. Only newly authored documentation is public; deployment source and history stay private pending redistribution rights.
- Validation: inspected both diagrams and rendered the guide at desktop/mobile widths; checked embedded images, navigation anchors, and publication contents. No infrastructure changes were made for this documentation update.

### 2026-10-28 — Publish the complete reusable lab
- Superseded the earlier documentation-only scope at the repository owner's explicit request: published the complete tracked source snapshot to msftse-org/ai-gateway-demo, retaining the architecture PNGs and offline guide.
- Included Terraform modules, APIM policies, clients, scripts, dashboards, runbooks, repository skills and source-provenance notice. Preserved the team repository history without importing private Git history.
- Updated the quick start to the public clone URL and removed obsolete documentation-only descriptions. Generated credentials, local configuration, Terraform state and runtime artifacts remain excluded.
- Validation: all 81 tracked paths and executable bits match between repositories; credential/environment scan, Terraform format/validate, Python/JSON syntax and shell checks passed. The generated clients/.env remains intentionally absent from the public snapshot. No Azure resources changed.
