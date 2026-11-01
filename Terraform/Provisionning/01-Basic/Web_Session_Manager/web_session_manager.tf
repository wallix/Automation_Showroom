# Bastion-wide setting: there is one per Bastion, and destroy leaves it in place.
resource "wallix-bastion_config_wsm" "main" {
  hostname   = var.wsm_hostname
  jwe_public = var.wsm_jwe_public_key
}
