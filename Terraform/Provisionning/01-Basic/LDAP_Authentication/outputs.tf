output "domain_name" {
  description = "Name of the LDAP authentication domain on the Bastion."
  value       = wallix-bastion_authdomain_ldap.corporate.domain_name
}

output "user_group" {
  description = "Bastion user group given to the members of the LDAP group."
  value       = wallix-bastion_usergroup.ldap_users.group_name
}
