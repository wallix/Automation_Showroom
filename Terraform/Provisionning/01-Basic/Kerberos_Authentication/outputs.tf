output "user_name" {
  description = "Bastion user that authenticates with Kerberos."
  value       = wallix-bastion_user.kerberos.user_name
}

output "external_authentication" {
  description = "Kerberos external authentication, to add to the user_auths of other users."
  value       = wallix-bastion_externalauth_kerberos.realm.authentication_name
}
