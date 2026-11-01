# Kerberos external authentication: the Bastion checks the users' tickets with the keys of the keytab.
resource "wallix-bastion_externalauth_kerberos" "realm" {
  authentication_name = "${local.name}-kerberos"
  description         = "Automation Showroom: Kerberos example"
  host                = var.kdc_host
  port                = 88
  ker_dom_controller  = var.realm
  keytab              = filebase64(var.keytab_file)
}

# Local Bastion user that authenticates with Kerberos: the external authentication is in its user_auths.
resource "wallix-bastion_user" "kerberos" {
  user_name          = local.user_name
  display_name       = "Kerberos user"
  email              = "${local.user_name}@example.com"
  profile            = "user"
  user_auths         = [wallix-bastion_externalauth_kerberos.realm.authentication_name]
  preferred_language = "en"
}
