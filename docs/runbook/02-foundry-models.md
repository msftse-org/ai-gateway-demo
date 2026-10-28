# 02 — Foundry models (3 min)

**Goal:** Show the audience the Microsoft Foundry side — the models the gateway
fronts — before we put API Management in front of them.

## Portal click-path

1. Open **Microsoft Foundry** portal → [ai.azure.com](https://ai.azure.com).
2. Select the project **`proj-aigw`** (endpoint in `clients/.env` →
   `PROJECT_ENDPOINT`).
3. Left nav → **Models + endpoints**. Show the three deployments:
   - `gpt-6.1-terra` on account 1 (primary chat backend)
   - `gpt-6.1-terra` on account 2 (second backend for load balancing)
   - `text-embedding-3-small` on account 1 (embeddings for the semantic cache)
4. Open one deployment → point out the **target URI** and that it is a standard
   Azure OpenAI endpoint. *"Today apps call this directly — no per-team limits,
   no shared cost view, no central policy. That's what we fix with the gateway."*

## CLI (optional)

```bash
az cognitiveservices account deployment list \
  -g rg-aigw-demo -n ai-aigw-1-7enh2q -o table
az cognitiveservices account deployment list \
  -g rg-aigw-demo -n ai-aigw-2-7enh2q -o table
```

*(Substitute the actual account names from `terraform output` if your suffix
differs.)*

## What you should see

- Three model deployments listed and `Succeeded`.
- Two distinct Foundry accounts hosting `gpt-6.1-terra` — the basis for the
  load-balancing demo in step 07.

## Talking point

These are the **backends**. Everything from here on is about governing access to
them through one gateway: authentication, rate limits, caching, safety, routing,
cost, and observability — without changing the models.

## Screenshot

`docs/assets/02-foundry-deployments.png`

➡️ Next: [03-apim-tour.md](03-apim-tour.md)
