# Built-in WEBAPP connection policy (API v3.12), read to fail at plan time on a Bastion without it.
data "wallix-bastion_connection_policy" "webapp" {
  connection_policy_name = "WEBAPP"
}

# The account the Bastion injects into the login form of the web application.
resource "wallix-bastion_domain" "webapp" {
  domain_name = var.domain_name
  description = "Accounts of the web applications"
}

resource "wallix-bastion_domain_account" "webapp" {
  domain_id     = wallix-bastion_domain.webapp.id
  account_name  = var.webapp_account_login
  account_login = var.webapp_account_login

  # Destroy the account before the application: the Bastion refuses to delete an application with an attached account.
  depends_on = [wallix-bastion_application.webapp]
}

resource "wallix-bastion_domain_account_credential" "webapp" {
  domain_id  = wallix-bastion_domain_account.webapp.domain_id
  account_id = wallix-bastion_domain_account.webapp.id
  type       = "password"
  password   = var.webapp_account_password
}

resource "wallix-bastion_application" "webapp" {
  application_name  = var.application_name
  description       = "Automation Showroom: web application example"
  category          = "web_application"
  connection_policy = data.wallix-bastion_connection_policy.webapp.connection_policy_name
  application_url   = var.application_url
  global_domains    = [wallix-bastion_domain.webapp.domain_name]

  # Automatic login: where the form is and which button submits it. Leave them null to log in by hand.
  login_form_url        = var.login_form_url
  login_button_selector = var.login_button_selector
}
