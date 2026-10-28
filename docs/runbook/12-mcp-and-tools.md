# 12 — MCP tool integration and versioning

The deployed integration is a Microsoft Learn MCP passthrough. No custom MCP server is provisioned. The agent's tool uses APIM; its model uses Foundry directly.

## Show the current definition

Open the project agent and inspect its Microsoft Learn tool URL. It should be the deployment's `/ms-learn-mcp` gateway endpoint. The default API does not require a subscription, so the inline tool has no credential connection. The MCP policy sets Accept to `application/json, text/event-stream`.

## Republish the tool

From the repository root, after exporting client configuration:

```bash
.venv/bin/python scripts/add-mcp-tool.py
./scripts/lab.sh test 06
```

The helper publishes a new version of the agent definition. Confirm its model, instructions and tool server URL, then inspect actual MCP call evidence in the test output. Version numbers depend on how often the helper has run; do not assume the next version is always 2.

## Discuss customer extensions

Authenticated tools, an approval policy, tool-specific rate/content controls, custom business-data tools and routing agent model traffic through a gateway are additional design and validation work. They are not automatically supplied by this proxy. Current tool approval is `never`; production tool authority needs an explicit decision.

Do not claim direct agent inference appears in gateway token metrics. Verify any required end-to-end tracing separately.

Next: [Cleanup](99-cleanup.md).
