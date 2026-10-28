# APIM AI Gateway + Microsoft Foundry — Live Demo Runbook

This runbook drives the in-person demo of **Azure API Management as an AI Gateway
in front of Microsoft Foundry**. Follow the numbered files in order. Each file
lists, for one demo segment:

- **Portal click-path** — what to open and click while screen-sharing.
- **CLI / script** — the exact command to run (tests live in `clients/`).
- **What the audience should see** — the expected output / "money shot".
- **Screenshot** — a placeholder path under `docs/assets/` for a captured image.

## Order of play

| # | File | Segment | Target |
|---|---|---|---|
| 00 | [00-prereqs.md](00-prereqs.md) | Subscription, permissions, `az login`, tooling | pre-meeting |
| 01 | [01-provision.md](01-provision.md) | `terraform apply`, verify outputs | pre-meeting |
| 02 | [02-foundry-models.md](02-foundry-models.md) | Foundry portal — model deployments | 3 min |
| 03 | [03-apim-tour.md](03-apim-tour.md) | APIM — API, products, subscriptions, backends, MI | 5 min |
| 03b | [03b-run-all-tests.md](03b-run-all-tests.md) | `run_all.py` → all-green + Test Run ID | 3 min |
| 04 | [04-call-direct.md](04-call-direct.md) | Direct chat call + token headers | 3 min |
| 05 | [05-token-limit.md](05-token-limit.md) | Rate limit (429) + daily quota (403) | 5 min |
| 06 | [06-semantic-cache.md](06-semantic-cache.md) | Vector cache hit | 4 min |
| 07 | [07-load-balancer.md](07-load-balancer.md) | Backend pool + circuit breaker | 5 min |
| 08 | [08-content-safety.md](08-content-safety.md) | Prompt moderation (200 vs 403) | 3 min |
| 08b | [08b-agent-end-to-end.md](08b-agent-end-to-end.md) | Prompt agent + Microsoft Learn MCP through the gateway | 6 min |
| 09 | [09-cost-view.md](09-cost-view.md) | Workbook — cost / chargeback | 5 min |
| 10 | [10-traces-logs.md](10-traces-logs.md) | App Insights traces, gateway logs, KQL | 5 min |
| 11 | [11-dashboard-full.md](11-dashboard-full.md) | Full workbook tour (all 12 sections) | 7 min |
| 12 | [12-mcp-and-tools.md](12-mcp-and-tools.md) | MCP architecture + **add a tool to the agent live** | 8 min |
| 99 | [99-cleanup.md](99-cleanup.md) | `terraform destroy` | post-meeting |

## Conventions

- All gateway values (URL, keys, deployment names, project endpoint) are written
  to [clients/.env](../../clients/.env) by `scripts/export-client-env.py` through `lab.sh deploy`. The test scripts and `run_all.py` read that file.
- **Python interpreter:** the test scripts require the project venv at
  `.venv/bin/python` (the system `python3` cannot import the Azure SDK).
  Every command below uses it explicitly.
- Model test requests are stamped with `x-test-run-id` and `x-user-id`, so the exact
  traffic for a run is filterable in the Azure Monitor workbook after telemetry ingestion.
