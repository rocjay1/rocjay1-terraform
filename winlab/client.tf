resource "azurerm_public_ip" "pip_client" {
  name                = "pip-Client01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_network_interface" "nic_client" {
  name                = "nic-Client01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_client.id
  }
}

resource "azurerm_network_interface_security_group_association" "client_rdp" {
  network_interface_id      = azurerm_network_interface.nic_client.id
  network_security_group_id = azurerm_network_security_group.rdp.id
}

resource "azurerm_windows_virtual_machine" "client" {
  name                = "Client01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_F8s_v2"

  computer_name  = "Client01"
  admin_username = "azureadmin"
  admin_password = random_password.admin.result

  network_interface_ids = [azurerm_network_interface.nic_client.id]

  tags = local.tags

  os_disk {
    name                 = "osdisk-Client01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // Windows 11 Pro, Gen2
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-pro"
    version   = "latest"
  }

  // Required for Gen2 images
  secure_boot_enabled = true
  vtpm_enabled        = true
}
