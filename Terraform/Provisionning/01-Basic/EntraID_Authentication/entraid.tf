# SAML service provider configuration, from the metadata of the Entra ID enterprise application.
resource "wallix-bastion_externalauth_saml" "entra" {
  authentication_name = "${local.name}-saml"
  description         = "Automation Showroom: Entra ID example"
  idp_metadata        = file(var.federation_metadata_file)
  timeout             = 30

  # Default claim names of an Entra ID SAML token.
  claim_customization {
    username    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    displayname = "http://schemas.microsoft.com/identity/claims/displayname"
    email       = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    group       = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"
  }
}

# The Bastion checks the tenant and client credentials with Microsoft when the domain is created.
resource "wallix-bastion_authdomain_azuread" "entra" {
  domain_name          = "${local.name}.entra"
  auth_domain_name     = var.auth_domain_name
  label                = "Entra ID (${local.name})"
  description          = "Automation Showroom: Entra ID example"
  external_auths       = [wallix-bastion_externalauth_saml.entra.authentication_name]
  entity_id            = var.tenant_id
  client_id            = var.client_id
  client_secret        = var.client_secret
  default_language     = "en"
  default_email_domain = var.auth_domain_name
}
