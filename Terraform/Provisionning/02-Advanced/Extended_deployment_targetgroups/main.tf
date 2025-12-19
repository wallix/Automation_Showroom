# WALLIX Bastion Extended Deployment - Target Groups and Authorizations
# This configuration provisions WALLIX Bastion resources with target groups and authorizations

terraform {
  required_version = ">= 1.0"
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.14.8"
      # source  = "terraform.local/local/wallix-bastion"
      # version = "0.0.0-dev"
    }
  }
}

# Provider configuration
provider "wallix-bastion" {
  ip       = var.bastion_ip
  user     = var.bastion_user
  password = var.bastion_password
  port     = var.bastion_port
}

# Local values for processing inventory files
locals {
  # Load inventory files
  users_inventory               = try(yamldecode(file("${path.module}/inventory/users.yaml")), {})
  devices_inventory             = try(yamldecode(file("${path.module}/inventory/devices.yaml")), {})
  domains_inventory             = try(yamldecode(file("${path.module}/inventory/domains.yaml")), {})
  groups_inventory              = try(yamldecode(file("${path.module}/inventory/groups.yaml")), {})
  timeframes_inventory          = try(yamldecode(file("${path.module}/inventory/timeframes.yaml")), {})
  target_groups_inventory       = try(yamldecode(file("${path.module}/inventory/target_groups.yaml")), {})
  authorizations_inventory      = try(yamldecode(file("${path.module}/inventory/authorizations.yaml")), {})
  target_accounts_inventory     = try(yamldecode(file("${path.module}/inventory/target_accounts.yaml")), {})
  connection_policies_inventory = try(yamldecode(file("${path.module}/inventory/connection_policies.yaml")), {})

  # Process users from inventory
  users = {
    for user in try(local.users_inventory.users, []) :
    user.user_name => user
  }

  # Process devices from inventory
  devices = {
    for device in try(local.devices_inventory.devices, []) :
    device.device_name => device
  }

  # Process device services from inventory (flatten services for all devices)
  device_services = merge([
    for device in try(local.devices_inventory.devices, []) : {
      for service in try(device.services, []) :
      "${device.device_name}_${service.id}" => merge(service, {
        device_name = device.device_name
      })
    }
  ]...)

  # Process domains from inventory
  domains = {
    for domain in try(local.domains_inventory.domains, []) :
    domain.domain_name => domain
  }

  # Process groups from inventory
  groups = {
    for group in try(local.groups_inventory.groups, []) :
    group.group_name => group
  }

  # Process timeframes from inventory
  timeframes = {
    for timeframe in try(local.timeframes_inventory.timeframes, []) :
    timeframe.name => timeframe
  }

  # Process target groups from inventory
  target_groups = {
    for target_group in try(local.target_groups_inventory.target_groups, []) :
    target_group.group_name => target_group
  }

  # Process connection policies from inventory
  connection_policies = {
    for policy_name, policy in try(local.connection_policies_inventory.connection_policies, {}) :
    policy_name => policy
  }

  # Create a simplified authorization mapping (one user group to one target group)
  authorizations = {
    for auth_name, auth in try(local.authorizations_inventory.authorizations, {}) :
    auth_name => {
      authorization_name           = auth_name
      description                  = auth.description
      user_group                   = auth.user_groups[0]   # Take first user group
      target_group                 = auth.target_groups[0] # Take first target group
      authorize_sessions           = auth.authorize_sessions
      subprotocols                 = auth.subprotocols
      authorize_password_retrieval = auth.authorize_password_retrieval
      approval_required            = auth.approval_required
      approvers                    = try(auth.approvers, [])
      active_quorum                = auth.active_quorum
      inactive_quorum              = auth.inactive_quorum
    }
  }

  # Process target accounts from inventory
  target_accounts = {
    for account_name, account in try(local.target_accounts_inventory.target_accounts, {}) :
    account_name => account
  }
}

# Create connection policies
resource "wallix-bastion_connection_policy" "connection_policies" {
  for_each = local.connection_policies

  connection_policy_name = each.value.policy_name
  description            = try(each.value.description, "")
  protocol               = each.value.protocol

  # Convert options map to JSON string if provided
  options = try(jsonencode(each.value.options), "")

  # Authentication methods (optional)
  authentication_methods = try(each.value.authentication_methods, [])
}

# Create domains
resource "wallix-bastion_domain" "domains" {
  for_each = local.domains

  domain_name = each.value.domain_name
  description = try(each.value.description, "")

  # Password change configuration
  enable_password_change            = try(each.value.enable_password_change, false)
  password_change_plugin            = try(each.value.password_change_plugin, "")
  password_change_plugin_parameters = try(each.value.password_change_plugin_parameters, "")
  password_change_policy            = try(each.value.password_change_policy, "")
}

# Create timeframes
resource "wallix-bastion_timeframe" "timeframes" {
  for_each = local.timeframes

  timeframe_name = each.value.name
  description    = each.value.description

  dynamic "periods" {
    for_each = each.value.periods
    content {
      start_time = periods.value.start_time
      end_time   = periods.value.end_time
      start_date = periods.value.start_date
      end_date   = periods.value.end_date
      week_days  = periods.value.week_days
    }
  }
}

# Create devices
resource "wallix-bastion_device" "devices" {
  for_each   = local.devices
  depends_on = [wallix-bastion_domain.domains]

  device_name = each.value.device_name
  host        = each.value.host
  description = try(each.value.description, "")
}

# Create device services
resource "wallix-bastion_device_service" "device_services" {
  for_each   = local.device_services
  depends_on = [wallix-bastion_device.devices, wallix-bastion_domain.domains]

  device_id         = wallix-bastion_device.devices[each.value.device_name].id
  service_name      = each.value.service_name
  port              = each.value.port
  protocol          = each.value.protocol
  connection_policy = try(each.value.connection_policy, "")
  global_domains    = []
  # global_domains   = [
  #   for domain_name in try(each.value.global_domains, []) :
  #   wallix-bastion_domain.domains[domain_name].id
  #   if domain_name != "" && domain_name != null && contains(keys(wallix-bastion_domain.domains), domain_name)
  # ]
  subprotocols = try(each.value.subprotocols, [])
}


# Create target groups
resource "wallix-bastion_targetgroup" "target_groups" {
  for_each = local.target_groups

  group_name  = each.value.group_name
  description = try(each.value.description, "")
}

# Create user groups
resource "wallix-bastion_usergroup" "groups" {
  for_each   = local.groups
  depends_on = [wallix-bastion_timeframe.timeframes]

  group_name  = each.value.group_name
  description = try(each.value.description, "")
  timeframes  = try(each.value.timeframes, ["business_hours"])
}

# Create users
resource "wallix-bastion_user" "users" {
  for_each   = local.users
  depends_on = [wallix-bastion_usergroup.groups]

  user_name    = each.value.user_name
  display_name = try(each.value.display_name, each.value.user_name)
  email        = try(each.value.email, "")
  profile      = try(each.value.profile, "user")
  user_auths   = try(each.value.user_auths, ["local_password"])
  password     = try(each.value.password, null)
  groups       = try(each.value.groups, [])
}

# Create target accounts
resource "wallix-bastion_device_localdomain_account" "target_accounts" {
  for_each   = local.target_accounts
  depends_on = [wallix-bastion_device.devices, wallix-bastion_domain.domains]

  account_name         = each.value.account_name
  description          = try(each.value.description, "")
  device_id            = wallix-bastion_device.devices[each.value.device_name].id
  domain_id            = wallix-bastion_domain.domains[each.value.domain_name].id
  account_login        = each.value.login
  auto_change_password = try(each.value.auto_change_password, false)
}

# Create authorizations
resource "wallix-bastion_authorization" "authorizations" {
  for_each = local.authorizations
  depends_on = [
    wallix-bastion_usergroup.groups,
    wallix-bastion_targetgroup.target_groups
  ]

  authorization_name = each.value.authorization_name
  description        = each.value.description
  user_group         = each.value.user_group
  target_group       = each.value.target_group

  # Authorization types
  authorize_sessions           = each.value.authorize_sessions
  subprotocols                 = each.value.subprotocols
  authorize_password_retrieval = each.value.authorize_password_retrieval

  # Approval configuration
  approval_required = each.value.approval_required
  approvers         = each.value.approvers

  active_quorum   = each.value.active_quorum
  inactive_quorum = each.value.inactive_quorum
}