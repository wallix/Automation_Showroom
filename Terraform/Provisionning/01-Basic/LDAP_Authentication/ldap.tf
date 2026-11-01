# Connection to the directory: the Bastion binds with a service account and searches the users under ldap_base.
resource "wallix-bastion_externalauth_ldap" "corporate" {
  authentication_name = "${local.name}-ldap"
  description         = "Automation Showroom: LDAP example"
  host                = var.ldap_host
  port                = var.ldap_port
  is_ssl              = true
  ca_certificate      = var.ldap_ca_file == null ? null : file(var.ldap_ca_file)
  timeout             = 10
  ldap_base           = var.ldap_base
  cn_attribute        = "uid"
  login_attribute     = "uid"
  login               = var.ldap_bind_dn
  password            = var.ldap_bind_password
}

# Authentication domain: the directory as a source of Bastion users.
resource "wallix-bastion_authdomain_ldap" "corporate" {
  domain_name          = "${local.name}.ldap"
  auth_domain_name     = var.auth_domain_name
  description          = "Automation Showroom: LDAP example"
  external_auths       = [wallix-bastion_externalauth_ldap.corporate.authentication_name]
  default_language     = "en"
  default_email_domain = var.auth_domain_name

  # Attributes read on the user entry. The Bastion has no default for them.
  group_attribute        = "memberOf"
  display_name_attribute = "cn"
  email_attribute        = "mail"
}

# Members of the LDAP group get this Bastion user group (and its authorizations) at login.
resource "wallix-bastion_usergroup" "ldap_users" {
  group_name  = "${local.name}-users"
  description = "Members of ${var.ldap_group_dn}"
  profile     = "user"
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_authdomain_mapping" "ldap_users" {
  domain_id      = wallix-bastion_authdomain_ldap.corporate.id
  user_group     = wallix-bastion_usergroup.ldap_users.group_name
  external_group = var.ldap_group_dn
}
