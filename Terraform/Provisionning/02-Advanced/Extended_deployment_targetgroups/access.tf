locals {
  # Accounts of each target group, one entry per service the account is used on.
  target_group_sessions = {
    for group in keys(local.target_groups) : group => flatten([
      for name, account in local.target_accounts : [
        for id in account.services : { account = name, service = "${account.device_name}_${id}" }
      ] if contains(account.target_groups, group)
    ])
  }
}

resource "wallix-bastion_targetgroup" "target_groups" {
  for_each = local.target_groups

  group_name  = each.key
  description = each.value.description

  # Sessions opened with the account on each of its services.
  dynamic "session_accounts" {
    for_each = local.target_group_sessions[each.key]
    content {
      account     = wallix-bastion_domain_account.accounts[session_accounts.value.account].account_name
      domain      = wallix-bastion_domain.domains[local.target_accounts[session_accounts.value.account].domain_name].domain_name
      domain_type = "global"
      device      = wallix-bastion_device.devices[local.device_services[session_accounts.value.service].device_name].device_name
      service     = wallix-bastion_device_service.services[session_accounts.value.service].service_name
    }
  }

  # Password checkout of the same accounts (authorize_password_retrieval in the authorization).
  dynamic "password_retrieval_accounts" {
    for_each = toset([for name, account in local.target_accounts : name if contains(account.target_groups, each.key)])
    content {
      account     = wallix-bastion_domain_account.accounts[password_retrieval_accounts.value].account_name
      domain      = wallix-bastion_domain.domains[local.target_accounts[password_retrieval_accounts.value].domain_name].domain_name
      domain_type = "global"
    }
  }
}

resource "wallix-bastion_authorization" "authorizations" {
  for_each = local.authorizations

  authorization_name           = each.key
  description                  = each.value.description
  user_group                   = wallix-bastion_usergroup.groups[each.value.user_group].group_name
  target_group                 = wallix-bastion_targetgroup.target_groups[each.value.target_group].group_name
  authorize_sessions           = true
  subprotocols                 = each.value.subprotocols
  authorize_password_retrieval = try(each.value.authorize_password_retrieval, false)
  is_recorded                  = true

  # The approval settings are only set when an approval is required (approval_required requires approvers).
  approval_required = try(each.value.approval_required, false) ? true : null
  approvers         = try(each.value.approval_required, false) ? [for name in each.value.approvers : wallix-bastion_usergroup.groups[name].group_name] : null
  active_quorum     = try(each.value.approval_required, false) ? each.value.active_quorum : null
  inactive_quorum   = try(each.value.approval_required, false) ? each.value.inactive_quorum : null
}
