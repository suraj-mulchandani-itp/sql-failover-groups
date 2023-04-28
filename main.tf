resource "azurerm_resource_group" "sql_rg" {
  name     = "database-rg"
  location = "Central India"
}

resource "azurerm_mssql_server" "primary" {
  name                         = "mssqlserver-primary"
  resource_group_name          = azurerm_resource_group.sql_rg.name
  location                     = azurerm_resource_group.sql_rg.location
  version                      = "12.0"
  administrator_login          = "admin-user"
  administrator_login_password = "#I@MM-@$ql07*pass-$"
}

resource "azurerm_mssql_server" "secondary" {
  name                         = "mssqlserver-secondary"
  resource_group_name          = azurerm_resource_group.sql_rg.name
  location                     = "East US"      # The failover server should be in another region
  version                      = "12.0"
  administrator_login          = "admin-user"
  administrator_login_password = "#I@MM-@$ql07*pass-$"
}

resource "azurerm_mssql_database" "db1" {
  name        = "exampledb1"
  server_id   = azurerm_mssql_server.primary.id
  sku_name    = "S1"
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = "200"
}

resource "azurerm_mssql_database" "db2" {
  name        = "exampledb2"
  server_id   = azurerm_mssql_server.primary.id
  sku_name    = "S1"
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = "200"
}

resource "azurerm_mssql_failover_group" "failover_group" {
  name      = "mssql-failover-group-example"
  server_id = azurerm_mssql_server.primary.id
  databases = [
    azurerm_mssql_database.db1.id,
    azurerm_mssql_database.db2.id
  ]

  partner_server {
    id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 80
  }

  tags = {
    environment = "dev"
    database    = "demo"
  }
}