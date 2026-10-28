# 09 — Estimate model usage cost

Open the workbook or Grafana dashboard and select the current Test Run ID and time range.
Set **Price / 1K input tokens** and **Price / 1K output tokens** to your applicable
Azure model rates. Both default to `unset`; cost results stay empty until prices
are configured. Changing the deployed model does not automatically update rates.

The estimate multiplies observed prompt/completion token counts by these rates.
Filter to one model run; a time window spanning a model upgrade cannot use one
price pair accurately. These are illustrative usage estimates, not billing or
chargeback records: semantic cache hits, provider prompt caching, embeddings,
agent calls that bypass the model gateway, and service charges need separate accounting.
Use Azure Cost Management for actual Azure spend.

Next: [10-traces-logs.md](10-traces-logs.md).
