"""Shared helpers for the AI-gateway demo test suite.

Every test script imports from here so the live-demo output is consistent:
* loads ``clients/.env``
* builds the APIM chat-completions / embeddings URLs
* stamps each request with ``x-test-run-id`` + ``x-user-id`` so the exact
  traffic is findable in the Azure Monitor workbook
* provides a tiny colored PASS/FAIL reporter (no test framework needed, but
  ``run_all.py`` is still able to import and run each ``main()``).
"""

from __future__ import annotations

import os
import sys
import time
import uuid
from pathlib import Path

import requests

# --------------------------------------------------------------------------- #
# .env loading (no external dependency)
# --------------------------------------------------------------------------- #
_ENV_PATH = Path(__file__).resolve().parent / ".env"


def load_env() -> dict[str, str]:
    """Read clients/.env into os.environ (does not overwrite real env vars)."""
    if _ENV_PATH.exists():
        for raw in _ENV_PATH.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip()
            os.environ.setdefault(key, value)
    return dict(os.environ)


def require(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        raise SystemExit(
            f"[config] missing '{name}'. Copy clients/.env.example to clients/.env "
            f"or run 'terraform output' to regenerate clients/.env."
        )
    return val


# --------------------------------------------------------------------------- #
# Test-run correlation
# --------------------------------------------------------------------------- #
def get_run_id() -> str:
    """One shared run-id for the whole suite (run_all.py sets X_TEST_RUN_ID)."""
    rid = os.environ.get("X_TEST_RUN_ID", "").strip()
    if not rid:
        rid = f"demo-{uuid.uuid4().hex[:12]}"
        os.environ["X_TEST_RUN_ID"] = rid
    return rid


def correlation_headers(user_id: str) -> dict[str, str]:
    return {
        "x-test-run-id": get_run_id(),
        "x-user-id": user_id,
    }


# --------------------------------------------------------------------------- #
# APIM endpoint helpers
# --------------------------------------------------------------------------- #
def _base() -> str:
    return require("APIM_GATEWAY_URL").rstrip("/")


def _api_path() -> str:
    return os.environ.get("APIM_API_PATH", "openai").strip("/")


def _api_version() -> str:
    return os.environ.get("OPENAI_API_VERSION", "2024-10-21").strip()


def chat_url(deployment: str | None = None) -> str:
    dep = deployment or require("CHAT_DEPLOYMENT")
    return (
        f"{_base()}/{_api_path()}/deployments/{dep}"
        f"/chat/completions?api-version={_api_version()}"
    )


def embeddings_url(deployment: str | None = None) -> str:
    dep = deployment or require("EMBEDDING_DEPLOYMENT")
    return (
        f"{_base()}/{_api_path()}/deployments/{dep}"
        f"/embeddings?api-version={_api_version()}"
    )


def chat(
    *,
    key: str,
    user_id: str,
    messages: list[dict],
    deployment: str | None = None,
    max_completion_tokens: int = 64,
    extra_headers: dict[str, str] | None = None,
    timeout: int = 60,
) -> requests.Response:
    """POST a chat completion through APIM and return the raw response."""
    headers = {
        "api-key": key,
        "Content-Type": "application/json",
        **correlation_headers(user_id),
        **(extra_headers or {}),
    }
    # The current reasoning model uses max_completion_tokens. Disable reasoning
    # for these short gateway demonstrations so the small budget yields text.
    body = {
        "messages": messages,
        "max_completion_tokens": max_completion_tokens,
        "reasoning_effort": "none",
        "stream": False,
    }
    return requests.post(chat_url(deployment), headers=headers, json=body, timeout=timeout)


# --------------------------------------------------------------------------- #
# Console reporting
# --------------------------------------------------------------------------- #
_USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def _c(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if _USE_COLOR else text


def info(msg: str) -> None:
    print(f"  {msg}")


def step(msg: str) -> None:
    print(_c("36", f"-> {msg}"))


def title(name: str) -> None:
    rid = get_run_id()
    print()
    print(_c("1;37", f"=== {name} ==="))
    print(_c("90", f"    test-run-id: {rid}"))


class Result:
    """Captures one test's PASS/FAIL outcome for the run_all.py summary."""

    def __init__(self, name: str, capability: str):
        self.name = name
        self.capability = capability
        self.passed = False
        self.expected = ""
        self.actual = ""
        self.detail = ""
        self.elapsed_ms = 0


def report(result: "Result", passed: bool, expected: str, actual: str, detail: str = "") -> bool:
    result.passed = passed
    result.expected = expected
    result.actual = actual
    result.detail = detail
    tag = _c("1;32", "PASS") if passed else _c("1;31", "FAIL")
    print(f"  [{tag}] expected={expected}  actual={actual}")
    if detail:
        print(_c("90", f"        {detail}"))
    return passed


def timed(fn):
    """Decorator: record elapsed ms on the Result returned by a test main()."""

    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = fn(*args, **kwargs)
        if isinstance(result, Result):
            result.elapsed_ms = int((time.perf_counter() - start) * 1000)
        return result

    return wrapper
