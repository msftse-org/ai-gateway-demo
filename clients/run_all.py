#!/usr/bin/env python3
"""run_all - AI-gateway demo orchestrator & PASS/FAIL summary.

Generates ONE shared x-test-run-id, runs tests 01-06 in order, and prints a
green/red summary table. At the end it prints the run-id and a ready-to-click
deep link to the Azure Monitor workbook filtered to this run, so the presenter
can paste the run-id into the workbook's "Test Run ID" parameter and watch every
test's effect appear on the dashboard.

Usage:
    python clients/run_all.py            # run everything
    python clients/run_all.py 01 03 05   # run a subset by number
"""

from __future__ import annotations

import importlib
import os
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import _common as c  # noqa: E402

TESTS = [
    ("01", "01_chat_basic"),
    ("02", "02_load_test"),
    ("03", "03_semantic_cache"),
    ("04", "04_load_balance"),
    ("05", "05_content_safety"),
    ("06", "06_invoke_agent"),
]


def _import_main(module_name: str):
    mod = importlib.import_module(module_name)
    return getattr(mod, "main")


def main(argv: list[str]) -> int:
    c.load_env()

    # One shared run-id for the entire suite.
    run_id = os.environ.get("X_TEST_RUN_ID") or f"demo-{uuid.uuid4().hex[:12]}"
    os.environ["X_TEST_RUN_ID"] = run_id

    wanted = {a.lstrip("0") or "0" for a in argv}
    selected = [t for t in TESTS if not wanted or t[0].lstrip("0") in wanted]

    print(c._c("1;37", "\n######  Azure API Management AI-Gateway demo  ######"))
    print(c._c("90", f"shared test-run-id: {run_id}\n"))

    results: list[c.Result] = []
    for num, module_name in selected:
        try:
            res = _import_main(module_name)()
        except SystemExit:
            raise
        except Exception as exc:  # noqa: BLE001 - keep the suite running
            res = c.Result(module_name, "(crashed)")
            c.report(res, False, expected="no exception", actual=type(exc).__name__, detail=str(exc)[:200])
        results.append(res)

    # ----------------------------------------------------------------- summary
    print(c._c("1;37", "\n================  SUMMARY  ================"))
    name_w = max(len(r.name) for r in results)
    cap_w = max(len(r.capability) for r in results)
    header = f"{'TEST':<{name_w}}  {'CAPABILITY':<{cap_w}}  {'RESULT':<6}  {'MS':>6}"
    print(header)
    print("-" * len(header))
    passed = 0
    for r in results:
        tag = c._c("1;32", "PASS") if r.passed else c._c("1;31", "FAIL")
        passed += int(r.passed)
        plain_tag = "PASS" if r.passed else "FAIL"
        pad = " " * (6 - len(plain_tag))
        print(f"{r.name:<{name_w}}  {r.capability:<{cap_w}}  {tag}{pad}  {r.elapsed_ms:>6}")
    print("-" * len(header))
    total = len(results)
    color = "1;32" if passed == total else "1;31"
    print(c._c(color, f"{passed}/{total} passed"))

    # ----------------------------------------------------- dashboard deep link
    workbook_url = os.environ.get("WORKBOOK_PORTAL_URL", "").strip()
    print(c._c("1;37", "\n----  View this run in the dashboard  ----"))
    print(f"  Test Run ID : {run_id}")
    if workbook_url:
        print(f"  Workbook    : {workbook_url}")
        print('  Paste the Test Run ID into the workbook\'s "Test Run ID" parameter.')
    else:
        print("  (WORKBOOK_PORTAL_URL not set in clients/.env - open the workbook from the portal.)")
    print()

    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
