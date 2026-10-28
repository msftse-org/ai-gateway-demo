#!/usr/bin/env python3
"""06 - Invoke the Foundry prompt agent (Azure assistant + Microsoft Learn MCP).

Capability: the pre-created prompt agent `agent-aigw-demo` runs server-side in
Foundry Agent Service. It is an Azure assistant whose tool is the Microsoft
Learn MCP server, fronted by the gateway (MCP passthrough). We invoke it via the
project's OpenAI Responses client and confirm it completes a turn, optionally
calling its MCP tool to ground the answer in Microsoft Learn docs.

Asserts:
  * the agent returns a non-empty answer (HTTP success through the Responses API)
  * the response includes an actual mcp_call item, proving tool execution

This requires Azure auth (DefaultAzureCredential / `az login`) and reaches the
Foundry project endpoint directly. The chat tests above prove the *gateway*
path; this proves agents work end-to-end and are governable.
"""

from __future__ import annotations

import json

import _common as c


@c.timed
def main() -> c.Result:
    r = c.Result("06_invoke_agent", "Prompt agent + Microsoft Learn MCP")
    c.title("06 - Invoke prompt agent")

    c.load_env()
    endpoint = c.require("PROJECT_ENDPOINT")
    agent_name = c.require("AGENT_NAME")

    try:
        from azure.ai.projects import AIProjectClient
        from azure.identity import DefaultAzureCredential
    except ImportError as exc:
        c.report(
            r,
            False,
            expected="agent answers a turn",
            actual="SDK not installed",
            detail=f"{exc} - install clients/requirements.txt into your venv.",
        )
        return r

    c.step(f"Connect to project and target agent '{agent_name}'")
    project = AIProjectClient(
        endpoint=endpoint,
        credential=DefaultAzureCredential(),
        allow_preview=True,  # required for agent_name routing
    )
    client = project.get_openai_client(agent_name=agent_name)

    c.step("Ask an Azure question that should trigger the Microsoft Learn MCP tool")
    # When an agent is targeted, the model must match the agent's own model.
    agent_model = c.require("CHAT_DEPLOYMENT")
    resp = client.responses.create(
        model=agent_model,
        input=(
            "Use Microsoft Learn to find which Azure API Management policy "
            "enforces a limit on LLM tokens, and name the policy."
        ),
    )

    text = getattr(resp, "output_text", "") or ""
    tool_calls = []
    for item in getattr(resp, "output", []) or []:
        itype = getattr(item, "type", "")
        if itype and ("tool" in itype or "function" in itype or "mcp" in itype):
            tool_calls.append(itype)

    c.info(f'agent answer: "{text.strip()[:120]}"')
    c.info(f"tool-call items observed: {tool_calls or 'none (answer may still use tool data)'}")

    answered = bool(text.strip())
    used_tool = "mcp_call" in tool_calls
    passed = answered and used_tool
    c.report(
        r,
        passed,
        expected="agent answers and executes its MCP tool",
        actual=f"answered={answered}, tool-evidence={used_tool}",
        detail=json.dumps(getattr(resp, "model_dump", lambda: {})())[:200] if not passed else "",
    )
    return r


if __name__ == "__main__":
    res = main()
    raise SystemExit(0 if res.passed else 1)
