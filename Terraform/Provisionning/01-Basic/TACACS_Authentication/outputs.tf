output "user_name" {
  description = "Bastion user that authenticates with TACACS+."
  value       = wallix-bastion_user.tacacs.user_name
}

output "external_authentication" {
  description = "TACACS+ external authentication, to add to the user_auths of other users."
  value       = wallix-bastion_externalauth_tacacs.server.authentication_name
}
