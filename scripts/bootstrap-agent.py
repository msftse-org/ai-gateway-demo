#!/usr/bin/env python3
"""Create or version the demo Foundry prompt agent used by this lab.

Invoked by Terraform (terraform_data.bootstrap_agent) after the Foundry project
and APIM gateway exist. Creates a prompt agent named `agent-aigw-demo` that is an
**Azure assistant** whose single tool is the **Microsoft Learn MCP** server,
fronted by the gateway (MCP passthrough). The agent model calls Foundry directly. Only its configured MCP tool traffic
traverses the separate APIM MCP API.

Design notes
------------
* The agent runs server-side in Foundry Agent Service. Its baseline model
  deployment is the Foundry chat deployment. Routing the agent's *model* traffic
  through APIM is an advanced option shown in runbook 12-mcp-and-tools.md (add a
  custom Azure OpenAI connection pointing at the gateway). This script creates
  the working baseline agent + tool.
* The MCP tool points at the gateway-fronted Microsoft Learn endpoint
  (MCP_SERVER_URL). The APIM MCP API is anonymous (subscriptionRequired=false),
  so the tool is published INLINE (server_url only) - which is what lets the
  tool card render in the Foundry portal Playground. To run the OPTIONAL
  governed variant (per-key rate-limit/quota), make the APIM MCP API require a
  subscription key, store that key in a project connection (Custom keys, key
  `api-key`), and set MCP_PROJECT_CONNECTION_NAME; the service then injects the
  header. Without MCP_SERVER_URL it falls back to the public Microsoft Learn
  MCP endpoint.
* Failures here are NON-FATAL: the script prints a clear WARNING, writes a status
  file, and exits 0 so `terraform apply` still succeeds. The agent can then be
  created manually by re-running this script or via the runbook.

Environment variables
---------------------
PROJECT_ENDPOINT       Foundry project endpoint
                       (https://<res>.services.ai.azure.com/api/projects/<proj>)
CHAT_DEPLOYMENT        Chat model deployment name (e.g. gpt-6.1-terra)
AGENT_NAME             Agent name (default: agent-aigw-demo)
MCP_SERVER_URL         Gateway-fronted Microsoft Learn MCP endpoint
                       (https://<apim>/ms-learn-mcp)
MCP_PROJECT_CONNECTION_NAME  OPTIONAL. Project connection (Custom keys) holding
                       the APIM subscription key as the `api-key` header. Set
                       only for the governed variant (APIM MCP API requiring a
                       key); leave unset to publish the tool inline (default,
                       portal-visible).
MCP_SERVER_LABEL       MCP tool label (default: microsoft_learn)
APIM_GATEWAY_URL       APIM gateway base URL (recorded for the runbook/clients)
APIM_API_PATH          API path on the gateway (recorded for clients)
APIM_SUBSCRIPTION_KEY  APIM subscription key (recorded for clients)
BOOTSTRAP_OUT          Path to write agent.json (default: ./.bootstrap/agent.json)
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

AGENT_INSTRUCTIONS = (
    "You are an Azure assistant. You help the user design, build, operate, and "
    "troubleshoot solutions on Microsoft Azure. Be concise and accurate. "
    "Whenever a question touches Azure services, APIs, CLI or SDK usage, "
    "configuration, limits, or best practices, use the Microsoft Learn tool to "
    "search and fetch official documentation and ground your answer in it. "
    "Reference the relevant doc when you use it, and say clearly when something "
    "is not covered by the documentation rather than guessing."
)

# Public Microsoft Learn MCP endpoint - used only as a fallback when the
# gateway-fronted MCP_SERVER_URL is not provided.
DEFAULT_MCP_SERVER_URL = "https://learn.microsoft.com/api/mcp"


def build_learn_mcp_tool(server_url=None, label=None, description=None, project_connection_id=None):
    """Build the Microsoft Learn MCPTool, routed through the gateway when possible.

    Resolves arguments from the environment when not passed explicitly:
      MCP_SERVER_URL, MCP_SERVER_LABEL, MCP_PROJECT_CONNECTION_NAME.
    By default the tool is published INLINE (server_url only, no connection),
    which makes its card render in the Foundry portal Playground and works
    against an anonymous APIM MCP API. For the OPTIONAL governed variant (APIM
    MCP API requiring a subscription key), store the key in a project connection
    (Custom keys, key `api-key`) and pass its name via project_connection_id /
    MCP_PROJECT_CONNECTION_NAME; the service injects the `api-key` header. Note:
    the portal Tools panel does not render a card for connection-backed MCP
    tools, though they still fire at runtime.
    """
    from azure.ai.projects.models import MCPTool

    server_url = (server_url or os.environ.get("MCP_SERVER_URL", "").strip() or DEFAULT_MCP_SERVER_URL)
    label = label or os.environ.get("MCP_SERVER_LABEL", "microsoft_learn").strip() or "microsoft_learn"
    description = description or "Search and fetch official Microsoft Learn / Azure documentation."
    if project_connection_id is None:
        project_connection_id = os.environ.get("MCP_PROJECT_CONNECTION_NAME", "").strip()

    kwargs = dict(
        server_label=label,
        server_url=server_url,
        server_description=description,
        require_approval="never",  # raise to "always" to show human-in-the-loop approval
    )
    if project_connection_id:
        kwargs["project_connection_id"] = project_connection_id
    return MCPTool(**kwargs)


def build_definition(model: str):
    """Build a typed PromptAgentDefinition (azure-ai-projects 2.x).

    An Azure assistant whose only tool is the gateway-fronted Microsoft Learn MCP
    server.
    """
    from azure.ai.projects.models import PromptAgentDefinition

    return PromptAgentDefinition(
        model=model,
        instructions=AGENT_INSTRUCTIONS,
        tools=[build_learn_mcp_tool()],
    )


def write_status(out_path: Path, payload: dict) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2))
    print(f"[bootstrap-agent] wrote {out_path}")


def main() -> int:
    endpoint = os.environ.get("PROJECT_ENDPOINT", "").strip()
    model = os.environ.get("CHAT_DEPLOYMENT", "").strip()
    agent_name = os.environ.get("AGENT_NAME", "agent-aigw-demo").strip()
    out_path = Path(
        os.environ.get("BOOTSTRAP_OUT", ".bootstrap/agent.json")
    ).expanduser()

    base_status = {
        "agent_name": agent_name,
        "model": model,
        "project_endpoint": endpoint,
        "apim_gateway_url": os.environ.get("APIM_GATEWAY_URL", ""),
        "apim_api_path": os.environ.get("APIM_API_PATH", ""),
        "mcp_server_url": os.environ.get("MCP_SERVER_URL", "") or DEFAULT_MCP_SERVER_URL,
        "mcp_server_label": os.environ.get("MCP_SERVER_LABEL", "microsoft_learn"),
    }

    if not endpoint or not model:
        write_status(
            out_path,
            {**base_status, "status": "skipped", "reason": "missing PROJECT_ENDPOINT or CHAT_DEPLOYMENT"},
        )
        print("[bootstrap-agent] WARNING: missing endpoint/model; skipping.")
        return 0

    try:
        from azure.ai.projects import AIProjectClient
        from azure.identity import DefaultAzureCredential
    except ImportError as exc:
        write_status(out_path, {**base_status, "status": "failed", "reason": f"import error: {exc}"})
        print(
            "[bootstrap-agent] WARNING: azure-ai-projects/azure-identity not installed. "
            "Install clients/requirements.txt and re-run scripts/bootstrap-agent.py.",
            file=sys.stderr,
        )
        return 0

    try:
        client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())

        existing = None
        try:
            existing = client.agents.get(agent_name)
        except Exception:
            existing = None

        definition = build_definition(model)
        # `definition` is a keyword-only parameter on create_version.
        agent = client.agents.create_version(agent_name, definition=definition)

        agent_id = getattr(agent, "id", None) or getattr(agent, "name", agent_name)
        version = getattr(agent, "version", None)
        write_status(
            out_path,
            {
                **base_status,
                "status": "created" if existing is None else "updated",
                "agent_id": agent_id,
                "version": version,
            },
        )
        print(f"[bootstrap-agent] agent '{agent_name}' ready (id={agent_id}, version={version}).")
        return 0
    except Exception as exc:  # noqa: BLE001 - non-fatal bootstrap
        write_status(out_path, {**base_status, "status": "failed", "reason": str(exc)})
        print(
            f"[bootstrap-agent] WARNING: agent creation failed: {exc}\n"
            "apply will continue; re-run scripts/bootstrap-agent.py after fixing.",
            file=sys.stderr,
        )
        return 0


if __name__ == "__main__":
    sys.exit(main())
