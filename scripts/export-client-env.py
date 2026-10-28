#!/usr/bin/env python3
"""Write the local test configuration from Terraform outputs without printing keys."""
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent
OUTPUTS = {
    "APIM_GATEWAY_URL": "apim_gateway_url",
    "APIM_API_PATH": "api_path",
    "TEAM_A_SUBSCRIPTION_KEY": "team_a_subscription_key",
    "TEAM_B_SUBSCRIPTION_KEY": "team_b_subscription_key",
    "CHAT_DEPLOYMENT": "chat_deployment_name",
    "EMBEDDING_DEPLOYMENT": "embedding_deployment_name",
    "PROJECT_ENDPOINT": "foundry_project_endpoint",
    "AGENT_NAME": "agent_name",
    "MCP_SERVER_URL": "mcp_server_url",
    "APP_INSIGHTS_CONNECTION_STRING": "app_insights_connection_string",
    "RESOURCE_GROUP": "resource_group_name",
    "APIM_NAME": "apim_name",
    "WORKBOOK_PORTAL_URL": "workbook_portal_url",
    "LOCATION": "location",
}


def main():
    result = subprocess.run(
        ["terraform", "output", "-json"], cwd=ROOT / "infrastructure",
        check=True, capture_output=True, text=True,
    )
    values = json.loads(result.stdout)
    config = {key: values[name]["value"] for key, name in OUTPUTS.items()}
    config.update(MCP_SERVER_LABEL="microsoft_learn", OPENAI_API_VERSION="2024-10-21")
    destination = ROOT / "clients" / ".env"
    fd = os.open(destination, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w") as handle:
        handle.write("".join(f"{key}={value}\n" for key, value in config.items()))
    print(f"Wrote {len(config)} settings to {destination} (permissions 0600).")


if __name__ == "__main__":
    main()
