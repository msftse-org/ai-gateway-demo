# 01 — Provision the lab

Run from the repository root. Provisioning time depends on Azure capacity; prepare before the customer meeting.

```bash
az login
az account set --subscription '<your-subscription-id>'
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit your publisher email, owner, naming and regions.
./scripts/lab.sh setup
./scripts/lab.sh plan
./scripts/lab.sh deploy
./scripts/lab.sh test
```

The plan includes the resource group, monitoring, Redis, Content Safety, two model accounts, three model deployments, a project, APIM policies/products/backends, RBAC and dashboards. The bootstrap creates a prompt agent; the deployment wrapper checks bootstrap status and writes local client settings.

Inspect nonsecret outputs with `terraform -chdir=infrastructure output apim_gateway_url` or `terraform -chdir=infrastructure output resource_group_name`. Do not print all JSON outputs during a presentation: they include credentials.

Resource names include the configured prefix and a random suffix. Use Terraform outputs and the generated client configuration to navigate to the actual deployment.

Next: [Foundry models](02-foundry-models.md).
