terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "a3c119ba-8f5f-466d-a19c-47f6445cfdb9"

  features {}
}

locals {
  location = "eastus"

  tags = {
    Project      = "winlab"
    DeployMethod = "Terraform"
  }

  // VM inventory: key = name, value indicates if public IP is needed
  vms = {
    DC01      = false
    DC02      = false
    Server01  = false
    Server02  = false
    Storage01 = false
    Client01  = true
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

resource "azurerm_network_security_group" "jumpbox" {
  name                = "nsg-client"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  tags = local.tags
}

resource "azurerm_public_ip" "pip" {
  for_each            = { for name, needs_pip in local.vms : name => needs_pip if needs_pip }
  name                = "pip-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_network_interface" "nic" {
  for_each            = local.vms
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = contains(keys(azurerm_public_ip.pip), each.key) ? azurerm_public_ip.pip[each.key].id : null
  }

  tags = local.tags
}

// Apply NSG only to the client NIC (the only one with a public IP)
resource "azurerm_network_interface_security_group_association" "jumpbox" {
  for_each                  = azurerm_public_ip.pip
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = local.vms
  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"

  admin_username = "azureadmin"
  admin_password = random_password.admin.result

  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    name                 = "osdisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.key == "Client01" ? "MicrosoftWindowsDesktop" : "MicrosoftWindowsServer"
    offer     = each.key == "Client01" ? "windows-11" : "WindowsServer"
    sku       = each.key == "Client01" ? "win11-23h2-pro" : "2025-Datacenter"
    version   = "latest"
  }

  computer_name = each.key

  tags = local.tags
}

output "admin_credentials" {
  value = {
    username = azurerm_windows_virtual_machine.vm["Client01"].admin_username
    password = random_password.admin.result
  }
  sensitive = true
}
