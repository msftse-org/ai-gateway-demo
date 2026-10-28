# 04 — Call the gateway directly (3 min)

**Goal:** The simplest possible proof: an app calls API Management exactly like
Azure OpenAI, APIM authenticates to Foundry with its managed identity, and the
response comes back with correlation headers — no model keys in the client.

## Command

```bash
.venv/bin/python clients/01_chat_basic.py
```

## What it does

Sends one chat completion to
`{APIM_GATEWAY_URL}/{APIM_API_PATH}/deployments/{CHAT_DEPLOYMENT}/chat/completions`
using only an **APIM subscription key** (`api-key` header) — never a Foundry key.
It asserts HTTP 200, a non-empty completion, and an `x-correlation-id` response
header.

## What you should see

- `[PASS]` with a 200 and a model answer.
- An `x-correlation-id` echoed back (the value to search for in App Insights in
  step 10).

## Talking points

- The client uses the **same wire format** as Azure OpenAI — adopting the gateway
  is a base-URL + key change, not a rewrite.
- The actual call to Foundry is **keyless**: APIM's managed identity holds
  `Cognitive Services OpenAI User`. No secrets live in the app.
- `x-correlation-id` ties this request to its end-to-end trace.

## Screenshot

`docs/assets/04-direct-call-200.png`

➡️ Next: [05-token-limit.md](05-token-limit.md)
