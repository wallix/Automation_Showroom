# Built-in SSH policy: the starting point of the copy.
data "wallix-bastion_connection_policy" "ssh" {
  connection_policy_name = "SSH"
}

locals {
  ssh_options = jsondecode(data.wallix-bastion_connection_policy.ssh.options)
  # Only what changes. options must hold the complete set, so it is merged into the built-in options, section by section.
  ssh_changes = {
    session = {
      inactivity_timeout = var.inactivity_timeout
    }
  }
}

resource "wallix-bastion_connection_policy" "ssh_timeout" {
  connection_policy_name = "${local.name}-ssh"
  description            = "Automation Showroom: SSH with an inactivity timeout"
  protocol               = data.wallix-bastion_connection_policy.ssh.protocol
  authentication_methods = data.wallix-bastion_connection_policy.ssh.authentication_methods
  options = jsonencode({
    for section in setunion(keys(local.ssh_options), keys(local.ssh_changes)) :
    section => merge(try(local.ssh_options[section], {}), try(local.ssh_changes[section], {}))
  })
}

resource "wallix-bastion_device" "server" {
  device_name = "${local.name}-srv01"
  host        = var.target_host
  description = "Automation Showroom: custom connection policy"
}

# The policy is set per service: other services keep their own.
resource "wallix-bastion_device_service" "ssh" {
  device_id         = wallix-bastion_device.server.id
  service_name      = "SSH"
  protocol          = "SSH"
  port              = 22
  connection_policy = wallix-bastion_connection_policy.ssh_timeout.connection_policy_name
  subprotocols      = ["SSH_SHELL_SESSION"]
}
