# The messages exist on every Bastion, one per language (_en, _fr, _de, _es, _ru): Terraform sets their text.
resource "wallix-bastion_connection_message" "login_en" {
  message_name = "login_en"
  message      = var.login_banner
}

resource "wallix-bastion_connection_message" "motd_en" {
  message_name = "motd_en"
  message      = var.message_of_the_day
}
