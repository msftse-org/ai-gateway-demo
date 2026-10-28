# 03 — APIM AI Gateway tour (5 min)

**Goal:** Orient the audience in API Management: the API, the per-team products
and subscriptions, the load-balanced backends, the managed identity, and where
the AI policies live.

## Portal click-path

1. Azure portal → resource group **`rg-aigw-demo`** → APIM instance
   (`apim-aigw-7enh2q`, value `APIM_NAME` in `clients/.env`).
2. **APIs** → the **Foundry / LLM API** (path `openai`). Show the operations
   (`/chat/completions`, `/embeddings`).
3. **Design → Inbound/Outbound processing → policy code view.** Walk the policy
   ([infrastructure/policies/policy-api.xml](../../infrastructure/policies/policy-api.xml))
   top-to-bottom — this is the whole story on one screen:
   - `llm-content-safety` — screen the prompt.
   - `llm-semantic-cache-lookup` — vector cache, varied per subscription.
   - `set-backend-service backend-id="foundry-pool"` + `authentication-managed-identity` — keyless routing to the pool.
   - `llm-emit-token-metric` — 5 dashboard dimensions (API ID, Subscription ID, Product, User ID, **Test Run ID**).
   - outbound `llm-semantic-cache-store` + correlation headers (`x-correlation-id`, `x-backend-host`, `x-test-run-id`).
4. **Products** → show **`dev-team-a`** (low TPM + daily quota) and
   **`dev-team-b`** (high TPM). Open each product's policy to show the
   `llm-token-limit`.
5. **Subscriptions** → one per product; these subscription IDs are the
   `counter-key` for token limits and a dashboard dimension.
6. **Backends** → the two Foundry backends + the **`foundry-pool`** load-balancer
   and the **`embeddings-backend`** used by the cache.
7. **Managed identity** (APIM → Security → Managed identities) → system-assigned
   identity has `Cognitive Services OpenAI User` on both Foundry accounts — so no
   keys are stored anywhere.

## CLI (optional)

```bash
az apim api list -g rg-aigw-demo -n apim-aigw-7enh2q -o table
az apim product list -g rg-aigw-demo -n apim-aigw-7enh2q -o table
```

## What you should see

- One LLM API, two products, two subscriptions, two model backends + a pool.
- The single API policy contains every AI-gateway capability in order.
- APIM authenticates to Foundry with its **managed identity** — no API keys.

## Screenshot

`docs/assets/03-apim-policy-code.png`

➡️ Next: [03b-run-all-tests.md](03b-run-all-tests.md)
