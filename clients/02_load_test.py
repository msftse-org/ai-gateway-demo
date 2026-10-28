#!/usr/bin/env python3
"""02 - Token rate limiting & daily quota (llm-token-limit).

Capability: product policy on `dev-team-a` (low tier) enforces a small
tokens-per-minute limit AND a daily token quota, keyed by the APIM subscription.

Asserts:
  * a burst of calls produces at least one 429 (tokens-per-minute exceeded), OR
    a 403 (daily token quota exceeded)
  * the gateway keeps serving 200s before the limit trips
Prints the count of 200 / 429 / 403.

Note: dev-team-a is provisioned at tokens-per-minute=500, token-quota=10000/day,
so a short burst of ~25 calls reliably trips the limit.
"""

from __future__ import annotations

import concurrent.futures as cf

import _common as c

BURST = 25
PROMPT = (
    "Write a detailed, multi-paragraph explanation of how HTTP load balancing "
    "works, including health probes, algorithms, and session affinity."
)


def _one(i: int, key: str) -> int:
    resp = c.chat(
        key=key,
        user_id="team-a-loadtest",
        messages=[{"role": "user", "content": PROMPT}],
        max_completion_tokens=256,
    )
    return resp.status_code


@c.timed
def main() -> c.Result:
    r = c.Result("02_load_test", "Token rate limit + daily quota")
    c.title("02 - Token rate limiting & quota (dev-team-a)")

    c.load_env()
    key = c.require("TEAM_A_SUBSCRIPTION_KEY")

    c.step(f"Fire {BURST} concurrent chat calls on the LOW-tier subscription")
    counts: dict[int, int] = {}
    with cf.ThreadPoolExecutor(max_workers=8) as pool:
        for status in pool.map(lambda i: _one(i, key), range(BURST)):
            counts[status] = counts.get(status, 0) + 1

    n200 = counts.get(200, 0)
    n429 = counts.get(429, 0)
    n403 = counts.get(403, 0)
    c.info(f"results: 200={n200}  429={n429}  403={n403}  other={ {k: v for k, v in counts.items() if k not in (200, 429, 403)} }")

    throttled = n429 > 0 or n403 > 0
    passed = throttled and n200 > 0
    c.report(
        r,
        passed,
        expected="some 200 then >=1 throttled (429 TPM or 403 quota)",
        actual=f"200={n200}, 429={n429}, 403={n403}",
        detail="No throttling seen - limit may be too high or burst too small." if not throttled else "",
    )
    return r


if __name__ == "__main__":
    res = main()
    raise SystemExit(0 if res.passed else 1)
