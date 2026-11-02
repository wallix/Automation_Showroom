resource "wallix-bastion_usergroup" "webapp" {
  group_name  = "${var.application_name}_users"
  description = "Users of the web application ${var.application_name}"
  timeframes  = ["allthetime"]
  users       = var.users
}

# The session account attaches the domain account to the application (application instead of device/service).
resource "wallix-bastion_targetgroup" "webapp" {
  group_name  = var.application_name
  description = "Web application ${var.application_name}"

  session_accounts {
    account     = wallix-bastion_domain_account.webapp.account_name
    domain      = wallix-bastion_domain.webapp.domain_name
    domain_type = "global"
    application = wallix-bastion_application.webapp.application_name
  }
}

resource "wallix-bastion_authorization" "webapp" {
  authorization_name = var.application_name
  user_group         = wallix-bastion_usergroup.webapp.group_name
  target_group       = wallix-bastion_targetgroup.webapp.group_name
  authorize_sessions = true
  subprotocols       = ["WEBAPP"]
  is_recorded        = true
}
