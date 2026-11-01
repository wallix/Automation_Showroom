# Current values of the banner section of the global configuration (wabengine).
data "wallix-bastion_configoption" "banner" {
  config_id    = "wabengine"
  options_list = ["banner"]
}

# Only the options listed in values are managed; the rest of wabengine is left as is.
resource "wallix-bastion_configoption" "banner" {
  config_id = "wabengine"
  values = jsonencode({
    banner = {
      enable  = var.banner_enabled
      type    = var.banner_type
      message = var.banner_message
    }
  })
}
