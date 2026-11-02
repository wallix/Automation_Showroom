# Global setting: replaces the certificate of the web and API listener, and trusts users_ca_file for user certificates.
resource "wallix-bastion_config_x509" "main" {
  server_public_key  = file(var.bastion_certificate_file)
  server_private_key = file(var.bastion_private_key_file)
  ca_certificate     = file(var.users_ca_file)
  enable             = true # Enables X509 authentication of the users.
}

# Global settings: revocation check of the user certificates. Destroy leaves them as they are on the Bastion.
resource "wallix-bastion_config_x509_crl" "main" {
  crl_check      = true
  crl_auto_fetch = var.crl_url
}

resource "wallix-bastion_config_x509_ocsp" "main" {
  ocsp_check             = true
  default_ocsp_responder = var.ocsp_responder
}

# Local user that logs in with the certificate whose subject is certificate_dn.
resource "wallix-bastion_user" "cert" {
  user_name          = "${local.name}-jdoe"
  display_name       = "Certificate user"
  email              = "${local.name}-jdoe@example.com"
  profile            = "user"
  user_auths         = ["local_x509"] # certificate_dn is refused without it.
  certificate_dn     = var.user_certificate_dn
  preferred_language = "en"
}
