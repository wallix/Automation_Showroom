output "target_group" {
  description = "Target group with the kill restriction."
  value       = wallix-bastion_targetgroup.servers.group_name
}

output "user_group" {
  description = "User group with the notify restriction: add the Bastion users to it."
  value       = wallix-bastion_usergroup.operators.group_name
}
