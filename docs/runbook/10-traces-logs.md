# 10 — Traces, logging & metrics (5 min)

**Goal:** Show end-to-end observability: from a single `x-correlation-id`
returned to the client, drill into the full gateway-to-Foundry transaction in
Application Insights, and run KQL over the gateway logs.

## Portal click-path

1. Azure portal → **Application Insights** (`appi-aigw-7enh2q`).
2. **Transaction search** → paste the `x-correlation-id` from step 04 (or any
   request) → open the end-to-end transaction. Show:
   - The APIM request, the dependency call to the Foundry backend, timing split
     (gateway overhead vs backend latency), status, and custom dimensions
     (Subscription ID, Product, User ID, **Test Run ID**, tokens).
3. **Logs (KQL)** → run queries over `ApiManagementGatewayLogs` and
   `customMetrics`.

## Sample KQL

Requests for one demo run, newest first:

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| extend TestRunId = tostring(parse_json(tostring(BackendResponseHeaders))['x-test-run-id'])
| project TimeGenerated, OperationId, ResponseCode, BackendId, DurationMs, CorrelationId
| order by TimeGenerated desc
| take 100
```

Token consumption by product (from the emitted metric):

```kusto
customMetrics
| where name == "Total Tokens" and timestamp > ago(1h)
| extend Product = tostring(customDimensions["Product"]),
         TestRunId = tostring(customDimensions["Test Run ID"])
| summarize Tokens = sum(valueSum) by Product, TestRunId
| order by Tokens desc
```

## What you should see

- A single transaction expands into gateway + backend spans with token custom
  dimensions.
- KQL returns this run's requests and per-product token totals.

## Talking points

- One correlation id ties client → gateway → model.
- Gateway overhead is **separable** from backend latency — you can prove the
  gateway is not your bottleneck.
- Everything the workbook shows is just KQL you can take into your own queries,
  alerts, and dashboards.

## Screenshot

`docs/assets/10-transaction-end-to-end.png`

➡️ Next: [11-dashboard-full.md](11-dashboard-full.md)
