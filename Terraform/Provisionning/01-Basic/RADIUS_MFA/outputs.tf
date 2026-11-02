output "domain_name" {
  description = "LDAP authentication domain that requires the RADIUS second factor."
  value       = wallix-bastion_authdomain_ldap.mfa.domain_name
}
