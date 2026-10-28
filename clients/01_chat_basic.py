#!/usr/bin/env python3
"""01 - Basic chat completion through the AI gateway.

Capability: the gateway transparently proxies an Azure OpenAI chat call to a
Foundry model using managed identity (no model key in the client).

Asserts:
  * HTTP 200
  * a non-empty assistant completion is returned
  * the gateway's correlation headers are echoed (x-correlation-id, x-backend-host)
"""

from __future__ import annotations

import _common as c


@c.timed
def main() -> c.Result:
    r = c.Result("01_chat_basic", "Proxy chat completion (MI auth)")
    c.title("01 - Basic chat completion")

    env = c.load_env()
    key = c.require("TEAM_B_SUBSCRIPTION_KEY")  # high tier, no quota in the way

    c.step("POST one chat completion through APIM")
    resp = c.chat(
        key=key,
        user_id="alice",
        messages=[{"role": "user", "content": "In one sentence, what is an API gateway?"}],
        max_completion_tokens=60,
    )

    ok_status = resp.status_code == 200
    content = ""
    usage = {}
    model = ""
    if ok_status:
        data = resp.json()
        content = (data.get("choices") or [{}])[0].get("message", {}).get("content", "")
        usage = data.get("usage", {})
        model = data.get("model", "")

    corr = resp.headers.get("x-correlation-id", "")
    backend = resp.headers.get("x-backend-host", "")

    c.info(f"status={resp.status_code}  correlation-id={corr or '(none)'}  backend={backend or '(none)'}")
    c.info(f"model={model or '(none)'}")
    if content:
        c.info(f'completion="{content.strip()[:80]}..."')
    if usage:
        c.info(f"tokens: prompt={usage.get('prompt_tokens')} completion={usage.get('completion_tokens')} total={usage.get('total_tokens')}")

    expected_model = c.require("CHAT_DEPLOYMENT")
    model_matches = model == expected_model or model.startswith(expected_model + "-")
    passed = ok_status and bool(content) and bool(corr) and model_matches
    c.report(
        r,
        passed,
        expected="200 + completion + correlation header + configured model",
        actual=f"{resp.status_code} + {'completion' if content else 'no-content'} + {'corr' if corr else 'no-corr'} + model={model}",
        detail=resp.text[:200] if not passed else "",
    )
    return r


if __name__ == "__main__":
    res = main()
    raise SystemExit(0 if res.passed else 1)
