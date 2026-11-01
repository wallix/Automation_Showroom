# Second factor: the RADIUS server checks the OTP (or push) after the LDAP password.
resource "wallix-bastion_externalauth_radius" "otp" {
  authentication_name = "${local.name}-radius"
  description         = "Automation Showroom: RADIUS second factor"
  host                = var.radius_host
  port                = 1812
  secret              = var.radius_secret
  timeout             = 10
}

# First factor: LDAP password, as in the LDAP_Authentication example.
resource "wallix-bastion_externalauth_ldap" "directory" {
  authentication_name = "${local.name}-ldap"
  description         = "Automation Showroom: RADIUS second factor"
  host                = var.ldap_host
  port                = 636
  is_ssl              = true
  timeout             = 10
  ldap_base           = var.ldap_base
  cn_attribute        = "uid"
  login_attribute     = "uid"
  login               = var.ldap_bind_dn
  password            = var.ldap_bind_password
}

# Users of this domain authenticate with external_auths first, then with secondary_auth.
resource "wallix-bastion_authdomain_ldap" "mfa" {
  domain_name          = "${local.name}.ldap"
  auth_domain_name     = var.auth_domain_name
  description          = "Automation Showroom: RADIUS second factor"
  external_auths       = [wallix-bastion_externalauth_ldap.directory.authentication_name]
  secondary_auth       = [wallix-bastion_externalauth_radius.otp.authentication_name]
  default_language     = "en"
  default_email_domain = var.auth_domain_name

  # Attributes read on the user entry. The Bastion has no default for them.
  group_attribute        = "memberOf"
  display_name_attribute = "cn"
  email_attribute        = "mail"
}
