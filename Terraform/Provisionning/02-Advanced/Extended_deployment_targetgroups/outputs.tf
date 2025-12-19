# Outputs for WALLIX Bastion Extended Deployment with Target Groups and Authorizations

output "deployment_summary" {
  description = "Summary of deployed WALLIX Bastion resources"
  value = {
    user_groups_count         = length(wallix-bastion_usergroup.groups)
    devices_count             = length(wallix-bastion_device.devices)
    device_services_count     = length(wallix-bastion_device_service.device_services)
    domains_count             = length(wallix-bastion_domain.domains)
    target_groups_count       = length(wallix-bastion_targetgroup.target_groups)
    target_accounts_count     = length(wallix-bastion_device_localdomain_account.target_accounts)
    authorizations_count      = length(wallix-bastion_authorization.authorizations)
    connection_policies_count = length(wallix-bastion_connection_policy.connection_policies)
    # account_assignments_count = length(wallix-bastion_targetgroup_account.target_group_accounts)
  }
}

output "target_groups" {
  description = "Created target groups"
  value = {
    for name, target_group in wallix-bastion_targetgroup.target_groups : name => {
      id          = target_group.id
      group_name  = target_group.group_name
      description = target_group.description
    }
  }
}

output "target_accounts" {
  description = "Created target accounts (passwords are sensitive)"
  value = {
    for name, account in wallix-bastion_device_localdomain_account.target_accounts : name => {
      id                   = account.id
      account_name         = account.account_name
      description          = account.description
      device_id            = account.device_id
      domain_id            = account.domain_id
      account_login        = account.account_login
      auto_change_password = account.auto_change_password
    }
  }
  sensitive = true
}

output "authorizations" {
  description = "Created authorizations"
  value = {
    for name, auth in wallix-bastion_authorization.authorizations : name => {
      id                           = auth.id
      authorization_name           = auth.authorization_name
      description                  = auth.description
      user_group                   = auth.user_group
      target_group                 = auth.target_group
      authorize_sessions           = auth.authorize_sessions
      authorize_password_retrieval = auth.authorize_password_retrieval
    }
  }
}

output "device_services" {
  description = "Created device services"
  value = {
    for name, service in wallix-bastion_device_service.device_services : name => {
      id                = service.id
      service_name      = service.service_name
      device_id         = service.device_id
      port              = service.port
      protocol          = service.protocol
      connection_policy = service.connection_policy
      subprotocols      = service.subprotocols
    }
  }
}

output "connection_policies" {
  description = "Created connection policies"
  value = {
    for name, policy in wallix-bastion_connection_policy.connection_policies : name => {
      id                     = policy.id
      connection_policy_name = policy.connection_policy_name
      description            = policy.description
      protocol               = policy.protocol
      type                   = policy.type
    }
  }
}
