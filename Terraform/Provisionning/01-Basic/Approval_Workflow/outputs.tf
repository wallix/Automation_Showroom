output "requester" {
  description = "User who requests the access (terraform output -json passwords for the passwords)."
  value       = wallix-bastion_user.requester.user_name
}

output "approver" {
  description = "User who approves it."
  value       = wallix-bastion_user.approver.user_name
}

output "passwords" {
  description = "Passwords of the requester and the approver."
  value       = { for k, p in random_password.users : k => p.result }
  sensitive   = true
}
