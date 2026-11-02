terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

provider "wallix-bastion" {
  ip                   = var.bastion_info_ip
  port                 = var.bastion_info_port
  user                 = var.bastion_info_user
  token                = var.bastion_info_token
  password             = var.bastion_info_password
  api_version          = var.bastion_info_api_version
  insecure_skip_verify = var.bastion_info_insecure_skip_verify
}

# One inventory file per type of object, in inventory/.
locals {
  connection_policies = yamldecode(file("${path.module}/inventory/connection_policies.yaml")).connection_policies
  devices             = { for d in yamldecode(file("${path.module}/inventory/devices.yaml")).devices : d.device_name => d }
  domains             = { for d in yamldecode(file("${path.module}/inventory/domains.yaml")).domains : d.domain_name => d }
  target_accounts     = yamldecode(file("${path.module}/inventory/target_accounts.yaml")).target_accounts
  target_groups       = yamldecode(file("${path.module}/inventory/target_groups.yaml")).target_groups
  timeframes          = yamldecode(file("${path.module}/inventory/timeframes.yaml")).timeframes
  groups              = yamldecode(file("${path.module}/inventory/groups.yaml")).groups
  users               = yamldecode(file("${path.module}/inventory/users.yaml")).users
  authorizations      = yamldecode(file("${path.module}/inventory/authorizations.yaml")).authorizations

  # One entry per service of each device, keyed "<device>_<service id>".
  device_services = merge([
    for name, device in local.devices : {
      for service in device.services : "${name}_${service.id}" => merge(service, { device_name = name })
    }
  ]...)
}
