# 08 — Content safety (3 min)

**Goal:** Show the gateway screening prompts **before** they reach a model. A
benign prompt passes (200); a harmful prompt is blocked at the gateway (403) and
never consumes model tokens.

## Command

```bash
.venv/bin/python clients/05_content_safety.py
```

## What it does

Sends one benign prompt and one harmful prompt through the gateway. Asserts the
benign call returns 200 and the harmful call is blocked (403/400).

## What you should see

```
  [PASS] expected=benign=200 and harmful blocked (403/400)  actual=benign=200, harmful=403
```

## The policy

Inbound `llm-content-safety` calls the Azure AI Content Safety backend and blocks
on **Hate / Violence / SelfHarm / Sexual** at/above the configured severity
threshold (`EightSeverityLevels`), with prompt shield enabled. See
[infrastructure/policies/policy-api.xml](../../infrastructure/policies/policy-api.xml).

## Talking points

- Moderation happens **at the edge** — blocked prompts cost zero model tokens.
- Centralized policy: every team and app inherits the same safety bar without
  changing their code.
- Threshold and categories are tunable per environment.

## Screenshot

`docs/assets/08-content-safety-block.png`

➡️ Next: [08b-agent-end-to-end.md](08b-agent-end-to-end.md)
