# locals {
#   server_names = [
#     "DC01",
#     "DC02",
#     "Server01",
#     "Server02",
#     "Storage01",
#   ]
# }

# resource "azurerm_network_interface" "nic" {
#   for_each            = toset(local.server_names)
#   name                = "nic-${each.key}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = local.tags

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.subnet.id
#     private_ip_address_allocation = "Static"
#   }
# }

# resource "azurerm_windows_virtual_machine" "vm" {
#   for_each            = toset(local.server_names)
#   name                = each.key
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   size                = "Standard_B2ms"

#   computer_name  = each.key
#   admin_username = "azureadmin"
#   admin_password = random_password.admin.result

#   network_interface_ids = [azurerm_network_interface.nic[each.key].id]

#   tags = local.tags

#   os_disk {
#     name                 = "osdisk-${each.key}"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2025-Datacenter"
#     version   = "latest"
#   }
# }
