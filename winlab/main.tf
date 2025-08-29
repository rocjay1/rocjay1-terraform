locals {
  location = "eastus"

  tags = {
    Project      = "winlab"
    DeployMethod = "Terraform"
  }
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "random_password" "admin" {
  length           = 20
  special          = true
  min_special      = 1
  override_special = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#-_"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-winlab-${random_string.suffix.result}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-winlab"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "rdp" {
  name                = "nsg-rdp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
