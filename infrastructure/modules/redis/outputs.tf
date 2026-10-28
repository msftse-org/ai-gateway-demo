output "cluster_id" {
  description = "Resource ID of the Redis Enterprise cluster."
  value       = azapi_resource.cluster.id
}

output "hostname" {
  description = "Hostname of the Redis cluster."
  value       = local.hostname
}

output "port" {
  description = "SSL port of the Redis cluster."
  value       = local.port
}

output "connection_string" {
  description = "StackExchange.Redis-style connection string for the APIM external cache."
  value       = "${local.hostname}:${local.port},password=${local.key},ssl=True,abortConnect=False"
  sensitive   = true
}
