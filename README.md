# Azure AI Gateway — architecture walkthrough

**A shared gateway for model governance, with visible evidence for every demo scenario.**

Customer-neutral documentation for architects and engineers. This public repository contains newly authored diagrams and an architecture guide only. Deployment code, credentials, environment settings, and Terraform state are not included.

[Download the standalone guide](docs/architecture-guide.html) · [Resource diagram](docs/diagrams/ai-gateway-architecture.png) · [Agent flow](docs/diagrams/agent-model-and-tool-flow.png)

## Deployed architecture

![Azure AI Gateway resource architecture: APIM applies model policies, uses safety and cache services, routes to two Foundry accounts, and emits monitoring data.](docs/diagrams/ai-gateway-architecture.png)

The model gateway applies team token limits, screens prompts, checks a semantic response cache, and sends cache misses to two Foundry backends. Both accounts host **GPT-6.1 Terra, version 2026-10-26**, verified in the demo on **28 October 2026**. Check model availability and quota for each new environment.

The picture shows logical request and data relationships; replies return along the request path. Equal pool weights do not guarantee a 50/50 result in a small batch. Workbook and Grafana independently query monitoring data and are outside the model request path.

## Resource inventory

One resource group contains the following resources and child configuration. Labels are generic so this material can be reused with other customers.

| Component | Deployed configuration | Purpose |
|---|---|---|
| API Management | Premium v2; `/openai` and `/ms-learn-mcp` APIs | Products, subscription keys, policies, backend pool and correlation |
| Foundry account 1 | GPT-6.1 Terra; Global Standard; 30,000 TPM capacity | Primary chat backend and host for the project |
| Foundry account 2 | Same model/version; Global Standard; 20,000 TPM capacity | Second chat backend for balancing |
| Embedding deployment | `text-embedding-3-small`, version 1, in account 1 | Embeds prompts for cache lookup; not the chat model |
| Foundry project | Project within account 1 | Holds the prompt agent definition and tool configuration |
| Foundry prompt agent | `agent-aigw-demo`; GPT-6.1 Terra; Microsoft Learn MCP | An assistant grounded in external documentation |
| Azure AI Content Safety | S0; gateway managed identity | Screens prompts before cache lookup and inference |
| Azure Managed Redis | Balanced B1; RediSearch; TLS | Vector-backed response cache; 120-second TTL |
| Application Insights | Workspace-backed | Request/dependency diagnostics and token metrics |
| Log Analytics | Shared workspace; 30-day retention | Stores monitoring data for investigation and queries |
| Azure Monitor Workbook | Demo workbook | Guided inspection by run, status, tokens and backend |
| Azure Managed Grafana | Standard; 28-panel dashboard | A second presentation surface over monitoring data |

The reference deployment places APIM in **Norway East** and other regional resources in **Sweden Central**. Regions are configurable. Both model accounts share a region; this is not a multi-region disaster-recovery demonstration. Global Standard account placement alone does not establish inference-processing residency.

Microsoft Learn MCP is an **external service**, not a deployed resource. No custom web chat UI, VM, AKS cluster, VNet, private endpoint, Key Vault, or custom MCP server is part of this lab.

## Model request flow

1. **Identify the caller.** The client sends an HTTPS Chat Completions request with an APIM product subscription key in `api-key`.
2. **Apply team limits.** Product policies count tokens per subscription. Team A demonstrates restrictive limits; Team B supports the other scenarios.
3. **Screen the prompt.** APIM calls Content Safety using managed identity. A blocked prompt returns 403 before model inference.
4. **Check the cache.** APIM calls the embedding deployment and checks Redis. Partitions include the subscription and deployment name. A match replays a stored response.
5. **Route a miss.** The backend pool selects a model account. APIM authenticates to Foundry using managed identity; retries and circuit breakers address selected failures.
6. **Return and observe.** Model output and correlation headers reach the client. Responses may be cached; diagnostics and token metrics support investigation.

A cache hit avoids a new **chat inference**, not every downstream call: the embedding lookup still runs. Semantic matching requires evaluation for answer quality and isolation.

## Agent and tool flow

![The Foundry agent calls its model directly; only its Microsoft Learn tool traffic passes through APIM’s separate MCP API.](docs/diagrams/agent-model-and-tool-flow.png)

The client invokes the prompt agent through the Foundry project's Responses API. The agent calls its model **directly in Foundry**, while its documentation tool requests pass through APIM's **separate `/ms-learn-mcp` API** to Microsoft Learn.

The project and agent belong to account 1. The model deployment is an account-level resource available to that project; the diagram groups them by runtime ownership, not model-resource ownership.

The `/openai` token, safety and cache policies **do not apply to the agent's direct model calls**. The MCP proxy is anonymous and tool approval is disabled for the demo. These are explicit demo settings, not a recommended production access model.

## Policies you can explain

| Capability | Mechanism | Observable behavior |
|---|---|---|
| Team token limits | `llm-token-limit` at product scope | Team A: 500 TPM and 10,000 tokens/day. Team B: 5,000 TPM without a configured daily quota |
| Prompt protection | `llm-content-safety` with prompt shield | Benign prompts succeed; a disallowed fixture returns 403. Demo category threshold: 2 on the eight-level scale |
| Semantic cache | `llm-semantic-cache-lookup` / `llm-semantic-cache-store` | Equivalent prompts can replay one response ID; similarity threshold 0.2, TTL 120 seconds |
| Model authentication | `authentication-managed-identity` | The client needs no Foundry model API key |
| Balancing | Two equal-priority, equal-weight pool members | `x-backend-host` identifies the backend on a cache miss |
| Resilience | Retry on backend 429/5xx; circuit breakers | Configured behavior; the test suite does not prove forced failover |
| Token visibility | `llm-emit-token-metric` | Prompt/completion/total-token metrics with caller/run dimensions |
| Correlation | `x-test-run-id`, `x-correlation-id`, `x-backend-host` | Connect a request to its monitoring evidence |

References: [token limits](https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy), [content safety](https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy), [semantic cache](https://learn.microsoft.com/en-us/azure/api-management/llm-semantic-cache-lookup-policy), and [backend pools](https://learn.microsoft.com/en-us/azure/api-management/backends). Values above describe this demo, not universal Azure defaults.

## Identity and trust boundaries

| Boundary | Current mechanism | Customer discussion |
|---|---|---|
| Client → model gateway | Product subscription key over HTTPS | A key identifies a subscription, not necessarily one end user |
| APIM → Foundry | System-assigned managed identity; Cognitive Services OpenAI User | Model accounts have local key authentication disabled |
| APIM → Content Safety | Managed identity; Cognitive Services User | Moderation is invoked by policy |
| APIM → Redis | TLS and Redis access key | Redis authentication differs from model authentication |
| Human → agent/portal | Microsoft Entra identity and Azure/project permissions | Access to the demo is separate from access to these public documents |
| Agent → Learn MCP | Anonymous gateway proxy; no tool approval prompt | Production tool authorization remains a design decision |
| Grafana → monitoring | Managed identity; Monitoring Reader | Read access scoped to the demo resource group |

Endpoints are public. A resource-group outline is an administrative grouping, not a private network. This demo screens prompts; it does not explicitly configure completion screening.

## Try a chat request in APIM

In an authorized environment, open **API Management → APIs → Foundry LLM API → Chat Completions → Test**.

| Field | Value |
|---|---|
| Method | `POST` |
| `deployment-id` | `gpt-6.1-terra` |
| Query parameter `api-version` | `2024-10-21` |
| Header `Content-Type` | `application/json` |
| Header `api-key` | Your APIM product subscription key |
| Header `x-test-run-id` | A unique label, such as `customer-walkthrough-01` |

Paste **only this JSON object** into Request body:

```json
{
  "messages": [
    {"role": "user", "content": "Explain what Azure API Management does in two sentences."}
  ],
  "max_completion_tokens": 150,
  "reasoning_effort": "none",
  "stream": false
}
```

URL: `https://<your-gateway>.azure-api.net/openai/deployments/gpt-6.1-terra/chat/completions?api-version=2024-10-21`.

The URL selects the deployment; no body `model` field is needed. These short calls disable reasoning so the budget can be used for visible text. Success means HTTP 200, nonempty `choices[0].message.content`, the expected `model`, and correlation headers. A missing `api-version` caused a backend 404 in the demo; a body not received as a JSON object caused a 400. Keep HTTP request lines and Markdown fences out of the body field.

## Customer walkthrough and evidence

| Step | Show | Explain |
|---|---|---|
| 1 · Orient | Resource architecture | Central model controls; two distinct backend accounts |
| 2 · Send | Successful chat request | Model, answer, tokens and correlation ID |
| 3 · Govern | Team A burst and prompt screening | Expected 429 throttling and selected 403 blocks |
| 4 · Reuse | Three equivalent prompts | Matching response IDs demonstrate cache replay; latency alone does not |
| 5 · Distribute | Both backend hosts | Balancing is observed; forced failover is a separate experiment |
| 6 · Ground | Agent answer and MCP call evidence | Distinguish the model and tool paths |
| 7 · Observe | Workbook/Grafana filtered by run | Allow ingestion time and isolate the relevant traffic |

On **28 October 2026**, all six executable scenarios passed in the reference environment after the model upgrade. A separate customer-body request returned HTTP 200 and the expected model. This is dated validation, not a promise of ongoing availability or customer access. Daily-quota exhaustion and regional disaster recovery were not established by these tests.

Cost rates default to **unset**. Enter applicable Azure input/output rates and filter to a run using one model before showing estimates. These are not invoices: embeddings, direct agent calls, cache behavior, and service charges require separate accounting.

## From demo to a customer design

1. **Define acceptance criteria:** users, prompts, model quality, latency, throughput, data handling and cost targets.
2. **Choose boundaries:** identity, API/tool authorization, endpoint exposure, connectivity and processing residency.
3. **Run a pilot:** evaluate safety and cache quality; measure quotas, token budgets and telemetry coverage.
4. **Prove operations:** test failure handling, recovery, monitoring, key lifecycle and deployment review before production adoption.

Open decisions: who may invoke which models/tools; whether cached answers can be shared; whether private connectivity is required; acceptable processing geography; whether the agent model path must also be governed; required RTO/RPO and cost controls. These are not presented as implemented features.

## Glossary and references

| Term | Meaning here |
|---|---|
| APIM | Azure API Management, the gateway and policy control point |
| Foundry | Azure's model and agent platform used by this demo |
| Deployment ID | Name selecting a model deployment in the request URL |
| TPM | Tokens per minute; distinguish model capacity from policy limits |
| Managed identity | Azure-managed workload identity used for service access tokens |
| Semantic cache | Response reuse based on prompt-vector similarity |
| TTL | Time to live; cache entries use 120 seconds here |
| MCP | Model Context Protocol; used to call Microsoft Learn tools |
| RBAC | Role-based access control |
| RTO / RPO | Recovery time objective / recovery point objective |

Diagrams use Azure-style product illustrations with explicit labels. Microsoft's [Azure icon collection and guidance](https://learn.microsoft.com/en-us/azure/architecture/icons/) is the reference for Azure iconography. These are explanatory illustrations, not an endorsement or portal screenshot.

## Repository contents

```text
README.md                               Customer-facing walkthrough
docs/architecture-guide.html           Standalone guide with embedded images
docs/diagrams/ai-gateway-architecture.png
docs/diagrams/agent-model-and-tool-flow.png
```

Download the HTML file and open it locally; GitHub shows its source rather than hosting it as a website. It needs no build step or separate image downloads. This repository does not include or grant access to the private deployment implementation.
