resource "wallix-bastion_externalauth_tacacs" "server" {
  authentication_name = "${local.name}-tacacs"
  description         = "Automation Showroom: TACACS+ example"
  host                = var.tacacs_host
  port                = 49
  secret              = var.tacacs_secret
}

# Local Bastion user whose password is checked by the TACACS+ server: the external authentication is in its user_auths.
resource "wallix-bastion_user" "tacacs" {
  user_name          = local.user_name
  display_name       = "TACACS+ user"
  email              = "${local.user_name}@example.com"
  profile            = "user"
  user_auths         = [wallix-bastion_externalauth_tacacs.server.authentication_name]
  preferred_language = "en"
}
