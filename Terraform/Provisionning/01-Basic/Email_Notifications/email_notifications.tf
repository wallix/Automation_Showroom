# Bastion-wide SMTP settings: there is one per Bastion, and destroy leaves them in place.
resource "wallix-bastion_config_smtp" "main" {
  server                = var.smtp_server
  port                  = var.smtp_port
  protocol              = var.smtp_protocol
  authentication_method = var.smtp_authentication_method
  user                  = var.smtp_user
  password              = var.smtp_password
  sender_name           = var.sender_name
  sender_email          = var.sender_email
  postmaster_email      = var.postmaster_email
}

resource "wallix-bastion_notification" "secops" {
  notification_name = "${local.name}-secops"
  description       = "Automation Showroom: events sent to the security team"
  enabled           = true
  type              = "email" # The only type.
  destination       = join(";", var.recipients)
  language          = "en"
  events            = var.events
}
