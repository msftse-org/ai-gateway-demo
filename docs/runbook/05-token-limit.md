# 05 — Token rate limit & daily quota (5 min)

**Goal:** Show per-team governance. The `dev-team-a` product has a low
tokens-per-minute limit **and** a daily token quota. Bursting against it trips
`429` (rate limited) and, once the daily quota is exhausted, `403`.

## Command

```bash
.venv/bin/python clients/02_load_test.py
```

## What it does

Fires ~25 concurrent chat calls using the **`dev-team-a`** subscription key
(`TEAM_A_SUBSCRIPTION_KEY`). It asserts that some calls return 200 and at least
one is throttled (`429` over-TPM, or `403` once the daily quota is gone). It
prints the status-code histogram.

## What you should see

```
  status 200 : 12
  status 429 : 13
  [PASS] ...
```

(Exact split varies with timing.) The key point: the same prompt that succeeds
for the high-tier team is throttled for the low-tier team.

## Portal corroboration

In the workbook (filtered to your Test Run ID) → **Errors & throttling** section
shows the 429/403 spike attributed to the `dev-team-a` subscription.

## The policy

This is `llm-token-limit` at **product** scope. Note that at product/global scope
only `counter-key`, `tokens-per-minute`, `token-quota`, `token-quota-period`, and
`retry-after-*` are allowed (output-token headers/variables are reserved for
API/operation scope). See
[infrastructure/policies/policy-product-low.xml](../../infrastructure/policies/policy-product-low.xml).

## Talking points

- `counter-key="@(context.Subscription.Id)"` → each team counts independently.
- TPM protects backends from noisy neighbours; the **daily quota** enforces a
  hard spend ceiling per team.
- A `429` includes a `Retry-After`; a `403` means the daily budget is spent.

## Screenshot

`docs/assets/05-token-limit-429.png`

➡️ Next: [06-semantic-cache.md](06-semantic-cache.md)
