variable "alert_email" {
  description = "Email address to notify when any VM runs for 24 hours or more"
  type        = string
}

locals {
  vm_ids = [for k, v in azurerm_windows_virtual_machine.vm : v.id]
}

resource "azurerm_monitor_action_group" "email" {
  name                = "ag-winlab-email"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "winlab"

  email_receiver {
    name          = "primary"
    email_address = var.alert_email
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "running_24h" {
  name                = "alert-vms-running-24h"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = local.vm_ids
  description         = "Alert if any VM has been running for the past 24 hours continuously."
  severity            = 2
  enabled             = true
  frequency           = "PT15M"
  window_size         = "P1D"

  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = azurerm_resource_group.rg.location

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "vmAvailabilityMetric"
    aggregation      = "Minimum"
    operator         = "Equals"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }

  tags = local.tags
}
