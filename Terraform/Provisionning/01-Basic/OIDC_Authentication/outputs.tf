output "redirect_uri" {
  description = "Redirection URI to register on the identity provider for the client."
  value       = wallix-bastion_externalauth_oidc.idp.redirect_uri
}

output "authdomain_id" {
  description = "ID of the OIDC authentication domain on the Bastion."
  value       = wallix-bastion_authdomain_oidc.idp.id
}

output "issuer" {
  description = "Issuer read from the discovery document."
  value       = local.oidc.issuer
}
