# Same resource as for LDAP, with is_active_directory and the AD login attribute.
resource "wallix-bastion_externalauth_ldap" "ad" {
  authentication_name = "${local.name}-ad"
  description         = "Automation Showroom: Active Directory example"
  host                = var.ad_host
  port                = 636
  is_ssl              = true
  ca_certificate      = var.ad_ca_file == null ? null : file(var.ad_ca_file)
  is_active_directory = true
  timeout             = 10
  ldap_base           = var.ad_base
  cn_attribute        = "sAMAccountName"
  login_attribute     = "sAMAccountName"
  login               = var.ad_bind_dn
  password            = var.ad_bind_password
}

resource "wallix-bastion_authdomain_ad" "corporate" {
  domain_name          = "${local.name}.ad"
  auth_domain_name     = var.ad_domain
  description          = "Automation Showroom: Active Directory example"
  external_auths       = [wallix-bastion_externalauth_ldap.ad.authentication_name]
  default_language     = "en"
  default_email_domain = var.ad_domain

  # Attributes read on the user entry. The Bastion has no default for them.
  group_attribute        = "memberOf"
  display_name_attribute = "displayName"
  email_attribute        = "mail"
}

# Members of the AD group get this Bastion user group (and its authorizations) at login.
resource "wallix-bastion_usergroup" "ad_users" {
  group_name  = "${local.name}-users"
  description = "Members of ${var.ad_group_dn}"
  profile     = "user"
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_authdomain_mapping" "ad_users" {
  domain_id      = wallix-bastion_authdomain_ad.corporate.id
  user_group     = wallix-bastion_usergroup.ad_users.group_name
  external_group = var.ad_group_dn
}
