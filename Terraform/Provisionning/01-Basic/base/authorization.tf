# Links the user group to the target group: who can open which session, with which protocol features.
resource "wallix-bastion_authorization" "demo" {
  authorization_name = local.name
  description        = "Automation Showroom: base example"
  user_group         = wallix-bastion_usergroup.demo.group_name
  target_group       = wallix-bastion_targetgroup.demo.group_name
  authorize_sessions = true
  # A subprotocol is only usable when the service enables it too.
  subprotocols = ["SSH_SHELL_SESSION", "SSH_SCP_UP", "SSH_SCP_DOWN", "SFTP_SESSION"]
  is_recorded  = true
  is_critical  = true
}
