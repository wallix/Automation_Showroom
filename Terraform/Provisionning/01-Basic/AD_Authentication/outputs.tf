output "domain_name" {
  description = "Name of the Active Directory authentication domain on the Bastion."
  value       = wallix-bastion_authdomain_ad.corporate.domain_name
}

output "user_group" {
  description = "Bastion user group given to the members of the AD group."
  value       = wallix-bastion_usergroup.ad_users.group_name
}
