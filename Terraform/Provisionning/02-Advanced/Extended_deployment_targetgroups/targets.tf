resource "wallix-bastion_domain" "domains" {
  for_each = local.domains

  domain_name = each.key
  description = each.value.description
}

resource "wallix-bastion_device" "devices" {
  for_each = local.devices

  device_name = each.key
  host        = each.value.host
  description = each.value.description
}

resource "wallix-bastion_device_service" "services" {
  for_each = local.device_services

  device_id    = wallix-bastion_device.devices[each.value.device_name].id
  service_name = each.value.service_name
  protocol     = each.value.protocol
  port         = each.value.port
  subprotocols = try(each.value.subprotocols, [])
  # A policy of the inventory (the reference orders creation and destruction), or a built-in one.
  connection_policy = try(wallix-bastion_connection_policy.policies[local.policy_keys[each.value.connection_policy]].connection_policy_name, each.value.connection_policy)
  # Global domains whose accounts are used on this service.
  global_domains = distinct([
    for account in local.target_accounts : wallix-bastion_domain.domains[account.domain_name].domain_name
    if account.device_name == each.value.device_name && contains(account.services, each.value.id)
  ])
}

resource "wallix-bastion_domain_account" "accounts" {
  for_each = local.target_accounts

  domain_id     = wallix-bastion_domain.domains[each.value.domain_name].id
  account_name  = each.key
  account_login = each.value.login
  description   = each.value.description
  # <device>:<service> pairs the account is used on.
  resources = [
    for id in each.value.services :
    "${wallix-bastion_device.devices[each.value.device_name].device_name}:${wallix-bastion_device_service.services["${each.value.device_name}_${id}"].service_name}"
  ]
}

resource "wallix-bastion_domain_account_credential" "passwords" {
  for_each = wallix-bastion_domain_account.accounts

  domain_id  = each.value.domain_id
  account_id = each.value.id
  type       = "password"
  password   = random_password.accounts[each.key].result
}
