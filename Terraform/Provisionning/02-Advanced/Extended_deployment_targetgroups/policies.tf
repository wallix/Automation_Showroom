# Built-in policy of each protocol used, read to copy its complete set of options.
data "wallix-bastion_connection_policy" "builtin" {
  for_each = toset([for policy in local.connection_policies : policy.protocol])

  connection_policy_name = each.key
}

locals {
  builtin_options = { for protocol, policy in data.wallix-bastion_connection_policy.builtin : protocol => jsondecode(policy.options) }
  policy_keys     = { for key, policy in local.connection_policies : policy.policy_name => key }
}

resource "wallix-bastion_connection_policy" "policies" {
  for_each = local.connection_policies

  connection_policy_name = each.value.policy_name
  description            = each.value.description
  protocol               = each.value.protocol
  authentication_methods = data.wallix-bastion_connection_policy.builtin[each.value.protocol].authentication_methods
  # options must hold the complete set: the built-in options, overridden section by section by the inventory.
  options = jsonencode({
    for section in setunion(keys(local.builtin_options[each.value.protocol]), keys(try(each.value.options, {}))) :
    section => merge(try(local.builtin_options[each.value.protocol][section], {}), try(each.value.options[section], {}))
  })
}
