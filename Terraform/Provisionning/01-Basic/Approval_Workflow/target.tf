resource "wallix-bastion_device" "critical" {
  device_name = "${local.name}-db01"
  host        = var.target_host
  description = "Critical server: access on approval only"
}

resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.critical.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = "SSH"
  subprotocols      = ["SSH_SHELL_SESSION"]
}

# Local domain: accounts that only exist on this device.
resource "wallix-bastion_device_localdomain" "local" {
  device_id   = wallix-bastion_device.critical.id
  domain_name = "local"
}

# One user at a time can check the password out, for one hour, extended by 30 minutes up to two hours.
resource "wallix-bastion_checkout_policy" "exclusive" {
  checkout_policy_name = "${local.name}-exclusive"
  description          = "Exclusive checkout, 1 h + 30 min extensions, 2 h max"
  enable_lock          = true
  duration             = 3600
  extension            = 1800
  max_duration         = 7200
}

resource "wallix-bastion_device_localdomain_account" "root" {
  device_id       = wallix-bastion_device.critical.id
  domain_id       = wallix-bastion_device_localdomain.local.id
  account_name    = var.target_account_login
  account_login   = var.target_account_login
  checkout_policy = wallix-bastion_checkout_policy.exclusive.checkout_policy_name
  services        = [wallix-bastion_device_service.ssh.service_name]
}

# Placeholder password: set the real one of the account, or let a password change policy rotate it.
resource "random_password" "root" {
  length           = 24
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

resource "wallix-bastion_device_localdomain_account_credential" "root" {
  device_id  = wallix-bastion_device.critical.id
  domain_id  = wallix-bastion_device_localdomain.local.id
  account_id = wallix-bastion_device_localdomain_account.root.id
  type       = "password"
  password   = random_password.root.result
}

resource "wallix-bastion_targetgroup" "critical" {
  group_name  = "${local.name}-critical"
  description = "Critical servers: sessions and password checkout"

  # Session through the Bastion, the password is injected.
  session_accounts {
    account     = wallix-bastion_device_localdomain_account.root.account_name
    domain      = wallix-bastion_device_localdomain.local.domain_name
    domain_type = "local"
    device      = wallix-bastion_device.critical.device_name
    service     = wallix-bastion_device_service.ssh.service_name
  }

  # Password shown to the user (checkout), under the checkout policy of the account.
  password_retrieval_accounts {
    account     = wallix-bastion_device_localdomain_account.root.account_name
    domain      = wallix-bastion_device_localdomain.local.domain_name
    domain_type = "local"
    device      = wallix-bastion_device.critical.device_name
  }
}
