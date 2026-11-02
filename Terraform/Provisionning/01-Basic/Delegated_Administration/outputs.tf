output "admin_user_name" {
  description = "Delegated administrator created by the example."
  value       = wallix-bastion_user.team_admin.user_name
}

output "admin_password" {
  description = "Password of the delegated administrator (terraform output -raw admin_password)."
  value       = random_password.team_admin.result
  sensitive   = true
}

output "managed_groups" {
  description = "The only user group and target group the administrator can reach."
  value = {
    user_group   = wallix-bastion_usergroup.team.group_name
    target_group = wallix-bastion_targetgroup.team.group_name
  }
}
