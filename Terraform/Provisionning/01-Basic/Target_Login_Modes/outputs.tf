output "target_group" {
  description = "Target group holding the three login modes."
  value       = wallix-bastion_targetgroup.modes.group_name
}

output "user_group" {
  description = "User group authorized on the target group: add the Bastion users to it."
  value       = wallix-bastion_usergroup.users.group_name
}
