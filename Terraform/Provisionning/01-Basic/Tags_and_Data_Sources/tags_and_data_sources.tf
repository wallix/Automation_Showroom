# Data source: reads an object Terraform doesn't manage, and fails at plan if it doesn't exist.
data "wallix-bastion_usergroup" "existing" {
  group_name = var.existing_user_group
}

resource "wallix-bastion_device" "web" {
  device_name = "${local.name}-web01"
  host        = var.target_host
  description = "Automation Showroom: tagged server"

  # The tags of the configuration replace those of the device, tags added outside Terraform included.
  tags {
    key   = "environment"
    value = "production"
  }

  tags {
    key   = "owner"
    value = "web-team"
  }
}

resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.web.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = "SSH" # Built-in connection policy.
  subprotocols      = ["SSH_SHELL_SESSION"]
}

# Interactive login: users type the account and password of the server, no account in the vault.
resource "wallix-bastion_targetgroup" "web" {
  group_name  = "${local.name}-web"
  description = "Automation Showroom: servers tagged owner=web-team"

  session_interactive_logins {
    device  = wallix-bastion_device.web.device_name
    service = wallix-bastion_device_service.ssh.service_name
  }
}

resource "wallix-bastion_authorization" "web" {
  authorization_name = "${local.name}-web"
  description        = "Automation Showroom: existing user group to the new server"
  user_group         = data.wallix-bastion_usergroup.existing.group_name
  target_group       = wallix-bastion_targetgroup.web.group_name
  authorize_sessions = true
  subprotocols       = ["SSH_SHELL_SESSION"]
  is_recorded        = true
}
