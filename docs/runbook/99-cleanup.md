# 99 — Cleanup

Use the checkout and local Terraform state belonging to the deployment you intend to remove. Record its resource-group name before destroying it:

```bash
terraform -chdir=infrastructure output -raw resource_group_name
./scripts/lab.sh destroy
```

Review the plan and confirm. Terraform removes the resources recorded in this deployment, including the gateway, models, cache, safety service, project, monitoring and dashboards. Service deletion can take time.

Verify the recorded group is gone:

```bash
az group exists --name '<resource-group-name>'
```

Preserve state until removal succeeds. Do not delete a shared resource group to work around an incomplete Terraform run; investigate remaining resources and ownership first. The provider is configured to purge its soft-deleted Cognitive Services accounts during destroy.

After successful removal, delete the local `clients/.env` and `.bootstrap/` if no longer needed. Keep the repository and virtual environment for future deployments. APIM, Redis and Grafana have ongoing service costs until their resources are removed.
