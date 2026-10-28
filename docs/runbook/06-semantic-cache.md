# 06 — Semantic (vector) cache (4 min)

**Goal:** Show that semantically-similar prompts return a **cached** answer with
no model call — cutting cost and latency. The cache is backed by Azure Managed
Redis (RediSearch) and keyed by prompt **embeddings**.

## Command

```bash
.venv/bin/python clients/03_semantic_cache.py
```

## What it does

1. **Primes** the cache once with "What is the capital city of France?".
2. Sends three differently-worded versions of the same question:
   - "What is the capital city of France?"
   - "Which city serves as the capital of France?"
   - "Tell me the capital of France."
3. Asserts all three return the **same response `id`**.

### Why response id, not latency

A cache **lookup** still computes the query embedding (a round-trip to the
embeddings backend), so a hit does **not** collapse to "tens of ms" — latency
alone is a flaky signal. A cache **hit** instead replays the *stored* response
verbatim, including its OpenAI `chatcmpl-...` id. A real model call always mints
a fresh id. So three paraphrases sharing one id proves they were served from the
vector cache.

## What you should see

```
  call 1 status=200 latency=... ms  id=...xxxxxxxxxxxx  "What is the capital city of France?"
  call 2 status=200 latency=... ms  id=...xxxxxxxxxxxx  "Which city serves as the capital of France?"
  call 3 status=200 latency=... ms  id=...xxxxxxxxxxxx  "Tell me the capital of France."
  distinct response ids=1 ...
  [PASS] expected=all 3 semantically-equivalent prompts share ONE cached response id
```

## The policy

Inbound `llm-semantic-cache-lookup` (varying by subscription, embeddings via the
`embeddings-backend` + managed identity) and outbound `llm-semantic-cache-store`
(2-minute TTL for the demo). See
[infrastructure/policies/policy-api.xml](../../infrastructure/policies/policy-api.xml).

> **Lesson baked into this lab:** the embeddings backend URL **must** end in
> `/embeddings`. The `llm-semantic-cache-lookup` policy POSTs directly to that
> backend; without the suffix it returns 404 and caching is **silently** skipped.

## Talking points

- Cache is **per subscription** (`vary-by`) so teams don't read each other's
  answers.
- Hyphens are stripped from the vary-by key because RediSearch treats `-` as
  negation.
- Repeated/near-duplicate prompts (FAQs, retries, fan-out) are where the savings
  land.

## Screenshot

`docs/assets/06-cache-hit.png`

➡️ Next: [07-load-balancer.md](07-load-balancer.md)
