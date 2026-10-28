#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
ACTION="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
case "$ACTION" in
  setup|plan|deploy|export|test|destroy) ;;
  *) printf '%s\n' 'Usage: ./scripts/lab.sh setup|plan|deploy|export|test|destroy [arguments]'; exit 0 ;;
esac
export PATH="$ROOT/.venv/bin:$PATH"
export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
export ARM_TENANT_ID="${ARM_TENANT_ID:-$(az account show --query tenantId -o tsv)}"
case "$ACTION" in
  setup)
    python3 -m venv "$ROOT/.venv"
    "$ROOT/.venv/bin/python" -m pip install -r clients/requirements.txt
    terraform -chdir=infrastructure init
    terraform -chdir=infrastructure validate
    ;;
  plan) terraform -chdir=infrastructure plan "$@" ;;
  deploy)
    terraform -chdir=infrastructure apply "$@"
    "$ROOT/.venv/bin/python" scripts/export-client-env.py
    "$ROOT/.venv/bin/python" - <<'PY'
import json
from pathlib import Path
p = Path('.bootstrap/agent.json')
if p.exists():
    status = json.loads(p.read_text()).get('status')
    if status not in ('created', 'updated'):
        raise SystemExit('Agent bootstrap did not succeed. Inspect .bootstrap/agent.json locally, then rerun bootstrap.')
    print('Agent bootstrap status:', status)
PY
    ;;
  export) "$ROOT/.venv/bin/python" scripts/export-client-env.py ;;
  test) "$ROOT/.venv/bin/python" clients/run_all.py "$@" ;;
  destroy) terraform -chdir=infrastructure destroy "$@" ;;
  *) printf '%s\n' 'Usage: ./scripts/lab.sh setup|plan|deploy|export|test|destroy [arguments]' ;;
esac
