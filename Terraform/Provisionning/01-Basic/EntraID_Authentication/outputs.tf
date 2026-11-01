output "domain_name" {
  description = "Entra ID authentication domain, to pass to the Group_Mapping example (authdomain_name)."
  value       = wallix-bastion_authdomain_azuread.entra.domain_name
}

output "sp_entity_id" {
  description = "Identifier (entity ID) to set in the SAML settings of the enterprise application."
  value       = wallix-bastion_externalauth_saml.entra.sp_entity_id
}

output "sp_assertion_consumer_service" {
  description = "Reply URL (assertion consumer service) to set in the SAML settings of the enterprise application."
  value       = wallix-bastion_externalauth_saml.entra.sp_assertion_consumer_service
}
