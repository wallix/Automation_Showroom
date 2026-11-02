resource "wallix-bastion_device" "server" {
  device_name = "${local.name}-srv01"
  host        = var.target_host
  description = "Automation Showroom: session restrictions"
}

resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.server.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = "SSH"
  subprotocols      = ["SSH_SHELL_SESSION"]
}

# Restriction on the targets: applies to every session opened on the targets of this group.
resource "wallix-bastion_targetgroup" "servers" {
  group_name  = local.name
  description = "Automation Showroom: session restrictions"

  # Interactive login keeps the example short: no vault account is needed.
  session_interactive_logins {
    device  = wallix-bastion_device.server.device_name
    service = wallix-bastion_device_service.ssh.service_name
  }

  restrictions {
    action      = "kill"
    rules       = "rm -rf /"
    subprotocol = "SSH_SHELL_SESSION"
  }
}

# Restriction on the users: applies to every SSH shell session of the members of this group.
resource "wallix-bastion_usergroup" "operators" {
  group_name  = local.name
  description = "Automation Showroom: session restrictions"
  timeframes  = ["allthetime"]

  restrictions {
    action      = "notify"
    rules       = "sudo"
    subprotocol = "SSH_SHELL_SESSION"
  }
}

resource "wallix-bastion_authorization" "operators" {
  authorization_name = local.name
  user_group         = wallix-bastion_usergroup.operators.group_name
  target_group       = wallix-bastion_targetgroup.servers.group_name
  authorize_sessions = true
  subprotocols       = ["SSH_SHELL_SESSION"]
  is_recorded        = true
}
