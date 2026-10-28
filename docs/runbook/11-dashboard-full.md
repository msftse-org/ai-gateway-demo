# 11 — Full dashboard tour (7 min)

**Goal:** Walk the complete Azure Monitor workbook — the single pane that proves
every capability shown so far, all filterable to one demo run.

## Portal click-path

1. Open the **Workbook** (`WORKBOOK_PORTAL_URL` in `clients/.env`).
2. Set the **Test Run ID** parameter to this run (or clear it for all-up view).
3. Walk the 12 sections in order:

| # | Section | What to point out |
|---|---|---|
| 1 | Header & parameters | Time range, APIM, API, Product, Subscription, User, **Test Run ID** filters. |
| 2 | Executive summary tiles | Total tokens, est. cost (USD), latency p50/p95, error %, cache-hit %, throttled. |
| 3 | Token consumption | Stacked tokens by Product + Subscription; prompt vs completion vs cached. |
| 4 | Cost view | Cost by Product / Subscription / User; editable price table. |
| 5 | Throughput & latency | Requests + p50/p95/p99; gateway vs backend latency. |
| 6 | Errors & throttling | 4xx/5xx split; dedicated 429 (rate) and 403 (quota) panels. |
| 7 | Semantic cache | Lookup/store events, hit ratio, token savings estimate. |
| 8 | Load balancer & circuit breaker | Backend selection counts; breaker trips. |
| 9 | Content safety | Blocked vs allowed; top blocked categories. |
| 10 | MCP tool calls | Calls per tool / latency / errors (populates once MCP is added in step 12). |
| 11 | Live trace explorer | Last 100 requests with correlation id, status, tokens; click-through. |
| 12 | Cost-saving recommendations | Subs near quota, low cache-hit APIs, hot backends → PTU hint. |

## Talking points

- One artifact, deployed by Terraform with the lab — reproducible, not hand-built.
- Each panel maps to a policy the audience just saw fire live.
- Filtering by **Test Run ID** isolates exactly the traffic from this session, so
  cause and effect are unmistakable.

## Screenshot

`docs/assets/11-workbook-overview.png`

➡️ Next: [12-mcp-and-tools.md](12-mcp-and-tools.md)
