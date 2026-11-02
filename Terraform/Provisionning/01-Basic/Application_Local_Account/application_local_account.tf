resource "wallix-bastion_application" "webapp" {
  application_name  = local.name
  description       = "Automation Showroom: application local account"
  category          = "web_application"
  connection_policy = "WEBAPP" # Built-in policy (API v3.12).
  application_url   = var.application_url
}

# Local domain of the application: its accounts can't be used on any other target.
resource "wallix-bastion_application_localdomain" "local" {
  application_id = wallix-bastion_application.webapp.id
  domain_name    = "local"
  description    = "Accounts of the web application ${local.name}"
}

resource "wallix-bastion_application_localdomain_account" "admin" {
  application_id = wallix-bastion_application_localdomain.local.application_id
  domain_id      = wallix-bastion_application_localdomain.local.id
  account_name   = var.app_account_login
  account_login  = var.app_account_login
}

resource "wallix-bastion_application_localdomain_account_credential" "admin" {
  application_id = wallix-bastion_application_localdomain_account.admin.application_id
  domain_id      = wallix-bastion_application_localdomain_account.admin.domain_id
  account_id     = wallix-bastion_application_localdomain_account.admin.id
  type           = "password"
  password       = var.app_account_password
}

# Session account of a local domain: domain_type "local", with the application that owns the domain.
resource "wallix-bastion_targetgroup" "webapp" {
  group_name  = local.name
  description = "Automation Showroom: application local account"

  session_accounts {
    account     = wallix-bastion_application_localdomain_account.admin.account_name
    domain      = wallix-bastion_application_localdomain.local.domain_name
    domain_type = "local"
    application = wallix-bastion_application.webapp.application_name
  }
}
