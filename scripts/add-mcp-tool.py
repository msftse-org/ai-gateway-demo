#!/usr/bin/env python3
"""(Re)publish the demo agent's Microsoft Learn MCP tool (runbook step 12, live).

The prompt agent `agent-aigw-demo` is an **Azure assistant** whose tool is the
**Microsoft Learn MCP** server, fronted by the gateway (MCP passthrough). This
script republishes a new agent version with that MCP tool wired in - the "add a
tool live" moment: the agent already has a gateway-proxied MCP tool, and we (re)attach its MCP capability in real time, demonstrating
versioning. Point `--server-url` at a different MCP server to attach another one.

By default the MCP tool is routed through APIM (MCP_SERVER_URL) and published
INLINE (server_url only, no connection) against the anonymous APIM MCP API - so
its card renders in the Foundry portal Playground. For the OPTIONAL governed
variant (APIM MCP API requiring a subscription key), store the key in a project
connection (Custom keys, key `api-key`) and set MCP_PROJECT_CONNECTION_NAME; the
service then injects the `api-key` header (note: connection-backed MCP tools do
not render a card in the portal Tools panel, though they still fire). Without
MCP_SERVER_URL it falls back to the public Microsoft Learn MCP endpoint
(https://learn.microsoft.com/api/mcp).

Usage:
    .inspect-venv/bin/python scripts/add-mcp-tool.py
    .inspect-venv/bin/python scripts/add-mcp-tool.py --server-url <url> --label <label>

Reads PROJECT_ENDPOINT, CHAT_DEPLOYMENT, AGENT_NAME, MCP_SERVER_URL,
MCP_SERVER_LABEL (and optional MCP_PROJECT_CONNECTION_NAME) from clients/.env (or env).
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Reuse the Azure-assistant instructions + Microsoft Learn MCP tool builder so
# the republished version matches the provisioned baseline.
sys.path.insert(0, str(Path(__file__.replace("add-mcp-tool.py", "")).resolve()))
import importlib.util

_BOOT = Path(__file__).with_name("bootstrap-agent.py")
_spec = importlib.util.spec_from_file_location("bootstrap_agent", _BOOT)
bootstrap_agent = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bootstrap_agent)  # type: ignore[union-attr]


def _load_env() -> None:
    env = Path(__file__).resolve().parent.parent / "clients" / ".env"
    if not env.exists():
        return
    for line in env.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        os.environ.setdefault(k.strip(), v.strip())


def main() -> int:
    parser = argparse.ArgumentParser(description="(Re)publish the demo agent's MCP tool.")
    parser.add_argument(
        "--server-url",
        default=None,
        help="MCP server URL. Defaults to MCP_SERVER_URL (gateway-fronted Microsoft Learn).",
    )
    parser.add_argument(
        "--label",
        default=None,
        help="MCP tool label. Defaults to MCP_SERVER_LABEL or 'microsoft_learn'.",
    )
    parser.add_argument(
        "--description",
        default=None,
        help="MCP tool description.",
    )
    args = parser.parse_args()

    _load_env()
    endpoint = os.environ.get("PROJECT_ENDPOINT", "").strip()
    model = os.environ.get("CHAT_DEPLOYMENT", "").strip()
    agent_name = os.environ.get("AGENT_NAME", "agent-aigw-demo").strip()
    if not endpoint or not model:
        print("ERROR: PROJECT_ENDPOINT and CHAT_DEPLOYMENT must be set (clients/.env).", file=sys.stderr)
        return 1

    from azure.ai.projects import AIProjectClient
    from azure.ai.projects.models import PromptAgentDefinition
    from azure.identity import DefaultAzureCredential

    # Build the Microsoft Learn MCP tool (gateway-routed unless overridden) and
    # publish a new version of the Azure-assistant agent with it.
    mcp_tool = bootstrap_agent.build_learn_mcp_tool(
        server_url=args.server_url,
        label=args.label,
        description=args.description,
    )
    server_url = mcp_tool.server_url
    label = mcp_tool.server_label

    definition = PromptAgentDefinition(
        model=model,
        instructions=bootstrap_agent.AGENT_INSTRUCTIONS,
        tools=[mcp_tool],
    )

    client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    agent = client.agents.create_version(agent_name, definition=definition)

    version = getattr(agent, "version", None)
    agent_id = getattr(agent, "id", None) or getattr(agent, "name", agent_name)
    routed = "via APIM gateway" if "azure-api.net" in (server_url or "") else "direct"
    print(f"Published MCP tool '{label}' ({server_url}) [{routed}].")
    print(f"Agent '{agent_name}' is now at version {version} (id={agent_id}).")
    print(f"Tools on this version: {label} (Microsoft Learn MCP).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
