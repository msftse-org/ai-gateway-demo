#!/usr/bin/env python3
"""Verify successful calls are served by both Foundry backend accounts.

Use semantically distinct prompts to reduce cache hits. The pool uses equal
priorities and weights. PASS requires all requests to succeed and at least two
backend hostnames to be observed; a single cached response is insufficient.
"""

from __future__ import annotations

import _common as c

PROMPTS = [
    "Name the largest planet in our solar system.",
    "What is the chemical formula for water?",
    "Who wrote Hamlet?",
    "How many sides does a triangle have?",
    "What does a compiler do?",
    "Name a musical instrument with strings.",
    "What currency is used in Japan?",
    "What gas do plants absorb during photosynthesis?",
    "What is the freezing point of water in Celsius?",
    "Name an ingredient in hummus.",
    "Which ocean is the largest?",
    "What organ pumps blood around the body?",
]
CALLS = len(PROMPTS)


@c.timed
def main() -> c.Result:
    r = c.Result("04_load_balance", "Backend pool load balancing")
    c.title("04 - Load balancing across backends")

    c.load_env()
    key = c.require("TEAM_B_SUBSCRIPTION_KEY")

    c.step(f"Send {CALLS} sequential calls and record the serving backend")
    hosts: dict[str, int] = {}
    statuses: dict[int, int] = {}
    for i in range(CALLS):
        resp = c.chat(
            key=key,
            user_id="lb-demo",
            messages=[{"role": "user", "content": PROMPTS[i]}],
            max_completion_tokens=5,
        )
        statuses[resp.status_code] = statuses.get(resp.status_code, 0) + 1
        host = resp.headers.get("x-backend-host", "(none)")
        hosts[host] = hosts.get(host, 0) + 1

    n200 = statuses.get(200, 0)
    c.info(f"status distribution: {statuses}")
    c.info("backend distribution:")
    for host, n in sorted(hosts.items(), key=lambda kv: -kv[1]):
        c.info(f"    {n:3d}  {host}")

    distinct = len([h for h in hosts if h != "(none)"])
    if distinct >= 2:
        actual = f"{distinct} distinct backends, {n200}/{CALLS} ok"
    else:
        actual = f"1 backend host, {n200}/{CALLS} ok"

    passed = n200 == CALLS and distinct >= 2
    c.report(
        r,
        passed,
        expected="all calls successful and >=2 distinct Foundry backend hosts",
        actual=actual,
        detail="Both backend hosts must be observed; cached replies alone do not prove balancing." if not passed else "",
    )
    return r


if __name__ == "__main__":
    res = main()
    raise SystemExit(0 if res.passed else 1)
