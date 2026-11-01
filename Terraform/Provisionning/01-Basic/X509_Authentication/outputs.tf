output "user_name" {
  description = "Bastion user that authenticates with its certificate."
  value       = wallix-bastion_user.cert.user_name
}
