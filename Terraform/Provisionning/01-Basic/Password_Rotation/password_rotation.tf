# Shape of the passwords the Bastion generates, and when it changes them (cron expression or @daily, @weekly...).
resource "wallix-bastion_passwordchangepolicy" "weekly" {
  password_change_policy_name = local.name
  description                 = "Automation Showroom: 20 characters, every character class, weekly"
  password_length             = 20
  lower_chars                 = 1
  upper_chars                 = 1
  digit_chars                 = 1
  special_chars               = 1
  change_period               = "@weekly"
}

# Global domain of an Active Directory: the Windows plugin changes the passwords through a domain controller.
resource "wallix-bastion_domain" "ad" {
  domain_name            = "${local.name}.ad"
  domain_real_name       = var.ad_domain_name
  description            = "Automation Showroom: password rotation"
  enable_password_change = true
  password_change_policy = wallix-bastion_passwordchangepolicy.weekly.password_change_policy_name
  password_change_plugin = "Windows"
  password_change_plugin_parameters = jsonencode({
    domain_controller_address = var.domain_controller
  })
}

resource "wallix-bastion_domain_account" "svc" {
  domain_id     = wallix-bastion_domain.ad.id
  account_name  = var.account_login
  account_login = var.account_login
  # Include the account in the rotation of its domain (false by default with this provider).
  auto_change_password = true
}

# Starting point of the rotation: the password the account has today.
resource "wallix-bastion_domain_account_credential" "svc" {
  domain_id  = wallix-bastion_domain_account.svc.domain_id
  account_id = wallix-bastion_domain_account.svc.id
  type       = "password"
  password   = var.account_password
}
