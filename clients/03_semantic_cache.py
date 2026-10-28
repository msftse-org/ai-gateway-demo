#!/usr/bin/env python3
"""03 - Semantic caching (llm-semantic-cache-lookup / -store).

Capability: the gateway stores LLM responses in a vector cache (Azure Managed
Redis) keyed by prompt *embeddings*. Semantically-similar later prompts return
the cached answer - no model call - cutting cost and latency.

Asserts (deterministic):
  * three semantically-equivalent prompts all return the SAME response id.

Why response id, not latency: a cache *lookup* still computes the query
embedding (a network round-trip to the embeddings backend), so a hit does not
collapse to "tens of ms" - latency alone is a flaky signal. A cache HIT instead
replays the *stored* response verbatim, including its OpenAI `chatcmpl-...` id.
A real model call always mints a fresh id. So if paraphrased prompts share one
id, the gateway served them from the vector cache. If the cache were broken,
every call would hit the model and every id would differ.

Latency for each call is printed for the demo narrative.
"""

from __future__ import annotations

import time

import _common as c

# Three ways of asking the same thing - same meaning, different words.
PROMPTS = [
    "What is the capital city of France?",
    "Which city serves as the capital of France?",
    "Tell me the capital of France.",
]


def _timed_call(key: str, prompt: str) -> tuple[int, float, str]:
    start = time.perf_counter()
    resp = c.chat(
        key=key,
        user_id="cache-demo",
        messages=[{"role": "user", "content": prompt}],
        max_completion_tokens=40,
    )
    elapsed = time.perf_counter() - start
    resp_id = ""
    try:
        resp_id = resp.json().get("id", "")
    except Exception:
        pass
    return resp.status_code, elapsed, resp_id


@c.timed
def main() -> c.Result:
    r = c.Result("03_semantic_cache", "Semantic (vector) response cache")
    c.title("03 - Semantic caching")

    c.load_env()
    key = c.require("TEAM_B_SUBSCRIPTION_KEY")

    # Prime the cache once so the measured calls below are warm HITs regardless
    # of what ran before. The store completes asynchronously, so give it a
    # moment before the measured calls.
    c.info("priming cache ...")
    _timed_call(key, PROMPTS[0])
    time.sleep(2.0)

    ids: list[str] = []
    statuses: list[int] = []
    latencies: list[float] = []
    for i, prompt in enumerate(PROMPTS):
        status, elapsed, resp_id = _timed_call(key, prompt)
        ids.append(resp_id)
        statuses.append(status)
        latencies.append(elapsed)
        short = resp_id[-12:] if resp_id else "(none)"
        c.info(f'call {i + 1} status={status} latency={elapsed * 1000:6.0f} ms  id=...{short}  "{prompt}"')
        time.sleep(1.0)

    unique = sorted(set(i for i in ids if i))
    first = latencies[0]
    fastest = min(latencies)
    c.info(
        f"distinct response ids={len(unique)}  "
        f"first={first * 1000:.0f} ms  fastest={fastest * 1000:.0f} ms"
    )

    passed = len(ids) == len(PROMPTS) and all(ids) and all(s == 200 for s in statuses) and len(unique) == 1
    c.report(
        r,
        passed,
        expected="all 3 semantically-equivalent prompts share ONE cached response id",
        actual=f"{len(unique)} distinct response id(s): "
        + (", ".join("..." + u[-12:] for u in unique) or "(none)"),
        detail=(
            "Multiple ids -> calls reached the model instead of the cache "
            "(cache cold, threshold too tight, or embeddings backend down)."
            if not passed
            else ""
        ),
    )
    return r


if __name__ == "__main__":
    res = main()
    raise SystemExit(0 if res.passed else 1)
