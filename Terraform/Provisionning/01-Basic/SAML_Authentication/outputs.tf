output "sp_entity_id" {
  description = "Entity ID of the Bastion, to register on the identity provider."
  value       = wallix-bastion_externalauth_saml.idp.sp_entity_id
}

output "sp_assertion_consumer_service" {
  description = "Assertion consumer service (reply URL) of the Bastion, to register on the identity provider."
  value       = wallix-bastion_externalauth_saml.idp.sp_assertion_consumer_service
}

output "idp_initiated_url" {
  description = "URL for a login started from the identity provider portal."
  value       = wallix-bastion_authdomain_saml.idp.idp_initiated_url
}
