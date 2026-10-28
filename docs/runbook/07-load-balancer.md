# 07 — Load balancer & circuit breaker (5 min)

**Goal:** Show that the gateway spreads traffic across **two Foundry backends**
and, if one starts failing, the circuit breaker shifts traffic to the healthy
one — transparently to the caller.

## Command

```bash
.venv/bin/python clients/04_load_balance.py
```

## What it does

Sends ~30 sequential chat calls through the **`foundry-pool`** backend pool. Each
response carries an `x-backend-host` header (set in the outbound policy from
`context.Request.Url.Host`, which `set-backend-service` rewrites to the selected
pool member). The test asserts the large majority succeed and reports the backend
distribution.

## What you should see

- ≥ 80% of calls return 200.
- `x-backend-host` reported (one or both Foundry hosts, depending on weighting
  and current circuit-breaker state).

## Optional: force a failover live

1. In the portal, temporarily disable/scale-to-zero the **primary** Foundry
   deployment (or block it) to make it return 429/5xx.
2. Re-run the script. The circuit breaker (trips on 429/5xx) marks the primary
   unhealthy and traffic shifts to the secondary.
3. Re-enable the primary; traffic rebalances after the trip duration.

## The policy & backend

- Pool with two Foundry backends (priority/weight) and a circuit breaker on
  429/5xx — see the APIM backend pool defined in
  [infrastructure/modules/apim/main.tf](../../infrastructure/modules/apim/main.tf).
- Inbound `set-backend-service backend-id="foundry-pool"`; the `<backend>`
  section retries on 429/5xx so a single trip is invisible to the client.

## Talking points

- One logical endpoint, many physical capacity sources (PTU + spillover, multi-
  region, multi-account).
- Priorities let you prefer reserved capacity (PTU) and spill to pay-as-you-go.
- The circuit breaker isolates an unhealthy backend so callers don't feel it.

## Screenshot

`docs/assets/07-backend-distribution.png`

➡️ Next: [08-content-safety.md](08-content-safety.md)
