# The Bastion as a SAML service provider of the identity provider described by the metadata.
resource "wallix-bastion_externalauth_saml" "idp" {
  authentication_name = "${local.name}-saml"
  description         = "Automation Showroom: SAML example"
  idp_metadata        = file(var.idp_metadata_file)
  timeout             = 30

  # Maps the attributes of the SAML assertion to the Bastion user fields (required with API v3.12).
  claim_customization {
    username    = var.saml_attributes.username
    displayname = var.saml_attributes.displayname
    email       = var.saml_attributes.email
    group       = var.saml_attributes.group
  }
}

# Login choice shown on the Bastion login page, under label.
resource "wallix-bastion_authdomain_saml" "idp" {
  domain_name          = "${local.name}.saml"
  auth_domain_name     = var.auth_domain_name
  label                = "Corporate SSO (${local.name})"
  description          = "Automation Showroom: SAML example"
  external_auths       = [wallix-bastion_externalauth_saml.idp.authentication_name]
  default_language     = "en"
  default_email_domain = var.auth_domain_name
}

# Members of the IdP group get this Bastion user group (and its authorizations) at login.
resource "wallix-bastion_usergroup" "idp_users" {
  group_name  = "${local.name}-users"
  description = "Members of the IdP group ${var.idp_group}"
  profile     = "user"
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_authdomain_mapping" "idp_users" {
  domain_id      = wallix-bastion_authdomain_saml.idp.id
  user_group     = wallix-bastion_usergroup.idp_users.group_name
  external_group = var.idp_group
}
