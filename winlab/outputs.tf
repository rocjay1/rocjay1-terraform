output "admin_credentials" {
  value = {
    username = azurerm_windows_virtual_machine.client.admin_username
    password = random_password.admin.result
  }
  sensitive = true
}
