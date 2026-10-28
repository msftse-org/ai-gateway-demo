# Azure Managed Redis (Redis Enterprise) cluster - external cache backing the APIM semantic cache.
# Uses azapi because the Balanced_* SKUs (Azure Managed Redis) are newer than the azurerm schema.
resource "azapi_resource" "cluster" {
  type      = "Microsoft.Cache/redisEnterprise@2024-10-01"
  name      = "redis-${var.name_prefix}-${var.suffix}"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  body = {
    sku = {
      name = var.sku_name
    }
  }

  response_export_values = ["properties.hostName"]
}

# Default database with the RediSearch module - required for APIM vector / semantic caching.
resource "azapi_resource" "database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2024-10-01"
  name      = "default"
  parent_id = azapi_resource.cluster.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"
      port             = 10000
      clusteringPolicy = "EnterpriseCluster"
      evictionPolicy   = "NoEviction"
      modules = [
        {
          name = "RediSearch"
        }
      ]
    }
  }

  response_export_values = ["properties.port"]
}

# Retrieve the access key so we can build the APIM external-cache connection string.
resource "azapi_resource_action" "keys" {
  type        = "Microsoft.Cache/redisEnterprise/databases@2024-10-01"
  resource_id = azapi_resource.database.id
  action      = "listKeys"
  method      = "POST"

  response_export_values = ["primaryKey"]
}

locals {
  hostname = azapi_resource.cluster.output.properties.hostName
  port     = 10000
  key      = azapi_resource_action.keys.output.primaryKey
}
