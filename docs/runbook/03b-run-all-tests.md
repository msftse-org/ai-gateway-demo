# 03b — Run the whole test suite (3 min)

**Goal:** A fast "everything is green" moment. Run all six capability tests at
once, then copy the shared **Test Run ID** and paste it into the workbook so
every later panel shows only this run's traffic.

## Command

```bash
.venv/bin/python clients/run_all.py
```

To run a subset (e.g. just cache + agent):

```bash
.venv/bin/python clients/run_all.py 03 06
```

## What you should see

```
######  Azure API Management AI-Gateway demo  ######
shared test-run-id: demo-xxxxxxxxxxxx
...
================  SUMMARY  ================
TEST               CAPABILITY                        RESULT      MS
-------------------------------------------------------------------
01_chat_basic      Proxy chat completion (MI auth)   PASS      ....
02_load_test       Token rate limit + daily quota    PASS      ....
03_semantic_cache  Semantic (vector) response cache  PASS      ....
04_load_balance    Backend pool load balancing       PASS      ....
05_content_safety  Prompt content safety screening   PASS      ....
06_invoke_agent    Prompt agent + Microsoft Learn MCP PASS      ....
-------------------------------------------------------------------
6/6 passed

----  View this run in the dashboard  ----
  Test Run ID : demo-xxxxxxxxxxxx
  Workbook    : https://portal.azure.com/.../workbook
```

## Do this next (drives the rest of the demo)

1. **Copy the printed `Test Run ID`** (e.g. `demo-xxxxxxxxxxxx`).
2. Open the **Workbook** link that `run_all.py` prints.
3. Paste the Test Run ID into the workbook's **"Test Run ID"** parameter.
4. Every later panel (tokens, cost, 429/403, cache, backends, content safety,
   agent) now reflects only this run.

> Each individual test is also runnable on its own in steps 04–08b for a slower,
> narrated walkthrough.

## Screenshot

`docs/assets/03b-run-all-green.png`

➡️ Next: [04-call-direct.md](04-call-direct.md)
