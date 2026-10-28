#!/usr/bin/env python3
"""Import the AI-gateway dashboard into Azure Managed Grafana.

Invoked by Terraform (terraform_data.import_dashboard) after the Grafana
instance and its RBAC role assignments exist. Loads the dashboard JSON,
substitutes the Log Analytics workspace resource ID placeholder, and POSTs it to
the Grafana data-plane API using an Azure AD token acquired via the Azure CLI.

Design notes
------------
* Authentication uses the Azure Managed Grafana data-plane AAD resource
  (ce34e7e5-485f-4d76-964f-b3d2b16d1e4f). The deployer is granted the
  "Grafana Admin" role on the instance by Terraform; that role is synced to a
  Grafana org role, so the first attempts may 401/403 until the sync completes —
  hence the retry loop.
* The dashboard JSON references the Log Analytics workspace by the literal
  placeholder __WORKSPACE_ID__ so the file stays free of Terraform ${...}
  interpolation that would clash with Grafana's own ${var} syntax.
* Failures here are NON-FATAL: the script prints a clear WARNING and exits 0 so
  `terraform apply` still succeeds. Re-run the script (or `terraform apply`) to
  retry the import.

Environment variables
---------------------
GRAFANA_URL     Grafana endpoint (https://<name>.<region>.grafana.azure.com)
WORKSPACE_ID    Log Analytics workspace resource ID
DASHBOARD_PATH  Path to the dashboard JSON template
"""

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

GRAFANA_AAD_RESOURCE = "ce34e7e5-485f-4d76-964f-b3d2b16d1e4f"
MAX_ATTEMPTS = 12
RETRY_DELAY_SECONDS = 15


def warn(message: str) -> None:
    print(f"WARNING: {message}", file=sys.stderr)


def get_token() -> str:
    result = subprocess.run(
        [
            "az",
            "account",
            "get-access-token",
            "--resource",
            GRAFANA_AAD_RESOURCE,
            "-o",
            "json",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)["accessToken"]


def load_dashboard(path: str, workspace_id: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        raw = handle.read()
    raw = raw.replace("__WORKSPACE_ID__", workspace_id)
    return json.loads(raw)


def post_dashboard(grafana_url: str, token: str, dashboard: dict) -> None:
    payload = json.dumps(
        {
            "dashboard": dashboard,
            "overwrite": True,
            "message": "Provisioned by Terraform (apim-ai-gateway-demo)",
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        f"{grafana_url.rstrip('/')}/api/dashboards/db",
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        body = json.loads(response.read().decode("utf-8"))
    print(f"Dashboard imported: {body.get('url', body)}")


def main() -> int:
    grafana_url = os.environ.get("GRAFANA_URL", "").strip()
    workspace_id = os.environ.get("WORKSPACE_ID", "").strip()
    dashboard_path = os.environ.get("DASHBOARD_PATH", "").strip()

    if not grafana_url or not workspace_id or not dashboard_path:
        warn("GRAFANA_URL, WORKSPACE_ID and DASHBOARD_PATH must all be set; skipping import.")
        return 0

    try:
        dashboard = load_dashboard(dashboard_path, workspace_id)
    except (OSError, ValueError) as exc:
        warn(f"Could not read/parse dashboard JSON: {exc}; skipping import.")
        return 0

    last_error: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            token = get_token()
            post_dashboard(grafana_url, token, dashboard)
            return 0
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            last_error = exc
            # 401/403 are expected while the Grafana Admin role assignment syncs.
            if exc.code in (401, 403):
                print(
                    f"Attempt {attempt}/{MAX_ATTEMPTS}: Grafana returned {exc.code} "
                    f"(role assignment still propagating). Retrying in {RETRY_DELAY_SECONDS}s...",
                    file=sys.stderr,
                )
            else:
                print(
                    f"Attempt {attempt}/{MAX_ATTEMPTS}: Grafana returned {exc.code}: {detail}. "
                    f"Retrying in {RETRY_DELAY_SECONDS}s...",
                    file=sys.stderr,
                )
        except (urllib.error.URLError, subprocess.CalledProcessError, TimeoutError) as exc:
            last_error = exc
            print(
                f"Attempt {attempt}/{MAX_ATTEMPTS}: {exc}. Retrying in {RETRY_DELAY_SECONDS}s...",
                file=sys.stderr,
            )

        if attempt < MAX_ATTEMPTS:
            time.sleep(RETRY_DELAY_SECONDS)

    warn(
        "Could not import the Grafana dashboard after "
        f"{MAX_ATTEMPTS} attempts ({last_error}). "
        "Re-run `terraform apply` or import "
        f"{dashboard_path} manually once you have the Grafana Admin role."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
