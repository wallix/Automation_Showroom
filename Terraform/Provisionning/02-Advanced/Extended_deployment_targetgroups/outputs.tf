output "user_passwords" {
  description = "Bastion password of each user (terraform output -json user_passwords); users change it at first login."
  value       = { for name, user in wallix-bastion_user.users : user.user_name => random_password.users[name].result }
  sensitive   = true
}

output "target_groups" {
  description = "Targets of each target group: account@domain@device:service."
  value = {
    for group, sessions in local.target_group_sessions : group => [
      for s in sessions :
      "${s.account}@${local.target_accounts[s.account].domain_name}@${local.device_services[s.service].device_name}:${local.device_services[s.service].service_name}"
    ]
  }
}

output "authorizations" {
  description = "User group and target group of each authorization."
  value       = { for name, auth in wallix-bastion_authorization.authorizations : name => "${auth.user_group} -> ${auth.target_group}" }
}
