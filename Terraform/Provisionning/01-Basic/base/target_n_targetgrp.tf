# A target is an account used on a service of a device: <account>@<domain>@<device>:<service>.

resource "wallix-bastion_device" "demo" {
  device_name = "${local.name}-srv01"
  host        = var.target_host
  description = "Automation Showroom: base example"
}

resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.demo.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = "SSH" # Built-in connection policy.
  subprotocols      = ["SSH_SHELL_SESSION", "SSH_SCP_UP", "SSH_SCP_DOWN", "SFTP_SESSION"]
  # Accounts of these global domains can be used on the service.
  global_domains = [wallix-bastion_domain.demo.domain_name]
}

# A global domain holds accounts shared by several devices; a local domain belongs to a single device.
resource "wallix-bastion_domain" "demo" {
  domain_name = "${local.name}.lab"
  description = "Automation Showroom: base example"
}

resource "wallix-bastion_domain_account" "demo" {
  domain_id     = wallix-bastion_domain.demo.id
  account_name  = var.target_account_login
  account_login = var.target_account_login
  # <device>:<service> pairs the account is used on.
  resources = ["${wallix-bastion_device.demo.device_name}:${wallix-bastion_device_service.ssh.service_name}"]
}

resource "wallix-bastion_domain_account_credential" "demo" {
  domain_id  = wallix-bastion_domain_account.demo.domain_id
  account_id = wallix-bastion_domain_account.demo.id
  type       = "password"
  password   = random_password.target_account.result
}

resource "wallix-bastion_targetgroup" "demo" {
  group_name  = local.name
  description = "Automation Showroom: base example"

  session_accounts {
    account     = wallix-bastion_domain_account.demo.account_name
    domain      = wallix-bastion_domain.demo.domain_name
    domain_type = "global"
    device      = wallix-bastion_device.demo.device_name
    service     = wallix-bastion_device_service.ssh.service_name
  }
}
