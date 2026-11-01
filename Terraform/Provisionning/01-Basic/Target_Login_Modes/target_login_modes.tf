resource "wallix-bastion_device" "server" {
  device_name = "${local.name}-srv01"
  host        = var.target_host
  description = "Automation Showroom: target login modes"
}

# The built-in SSH policy allows PASSWORD_MAPPING and PASSWORD_INTERACTIVE, needed by the first two modes.
resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.server.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = "SSH"
  subprotocols      = ["SSH_SHELL_SESSION"]
}

# Vault account for the scenario mode only: it doesn't open the session.
resource "wallix-bastion_domain" "scenario" {
  domain_name = "${local.name}.lab"
  description = "Automation Showroom: target login modes"
}

resource "wallix-bastion_domain_account" "scenario" {
  domain_id     = wallix-bastion_domain.scenario.id
  account_name  = var.scenario_account_login
  account_login = var.scenario_account_login
}

resource "wallix-bastion_domain_account_credential" "scenario" {
  domain_id  = wallix-bastion_domain_account.scenario.domain_id
  account_id = wallix-bastion_domain_account.scenario.id
  type       = "password"
  password   = random_password.scenario_account.result
}

# Demo value: a real account needs its real password.
resource "random_password" "scenario_account" {
  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

resource "wallix-bastion_targetgroup" "modes" {
  group_name  = local.name
  description = "Automation Showroom: target login modes"

  # Account mapping: the Bastion logs in with the login and password the user gave to the Bastion.
  session_account_mappings {
    device  = wallix-bastion_device.server.device_name
    service = wallix-bastion_device_service.ssh.service_name
  }

  # Interactive login: the user types the login and password of the server when the session starts.
  session_interactive_logins {
    device  = wallix-bastion_device.server.device_name
    service = wallix-bastion_device_service.ssh.service_name
  }

  # Scenario account: a vault account for the scenario of the session, not used to log in (global domain: no device).
  session_scenario_accounts {
    account     = wallix-bastion_domain_account.scenario.account_name
    domain      = wallix-bastion_domain.scenario.domain_name
    domain_type = "global"
  }
}

resource "wallix-bastion_usergroup" "users" {
  group_name  = local.name
  description = "Automation Showroom: target login modes"
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_authorization" "modes" {
  authorization_name = local.name
  user_group         = wallix-bastion_usergroup.users.group_name
  target_group       = wallix-bastion_targetgroup.modes.group_name
  authorize_sessions = true
  subprotocols       = ["SSH_SHELL_SESSION"]
  is_recorded        = true
}
