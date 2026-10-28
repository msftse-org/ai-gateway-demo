# 08b — Prompt agent, end to end

The agent model calls Foundry directly. Its Microsoft Learn MCP tool calls APIM `/ms-learn-mcp`, which forwards to the public Learn MCP service. Do not present the model API's token limits, cache, safety policy or balancing as controls on the agent model path.

```bash
./scripts/lab.sh test 06
```

The test targets the saved agent through the Foundry project, asks an Azure question, and checks both an answer and actual MCP tool-call evidence. Inspect `mcp_list_tools` and `mcp_call` output items rather than assuming documentation text proves a tool ran.

The MCP API is anonymous in this lab and only has its own Accept-header policy. Tool approval is set to `never`. Gateway logs can show the tool proxy traffic, but direct agent inference is not automatically represented in APIM token totals or frontend run-header correlation.

Open Foundry → your project → Agents → `agent-aigw-demo`, inspect its tool URL, and ask: “Use Microsoft Learn to find the APIM policy that limits LLM tokens.”

Next: [Cost view](09-cost-view.md).
