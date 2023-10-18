
# Authorization
### USERS
resource "wallix-bastion_authorization" "demo" {

  authorization_name = "authorization-${random_pet.user.id}"
  user_group         = wallix-bastion_usergroup.demo.group_name
  target_group       = wallix-bastion_targetgroup.demo.group_name
  authorize_sessions = true
  is_critical        = true
  subprotocols = [ # STATIC CODE
    "RDP",
    "RDP_CLIPBOARD_UP",
    "RDP_CLIPBOARD_DOWN",
    "RDP_CLIPBOARD_FILE",
    "RDP_PRINTER",
    "RDP_COM_PORT",
    "RDP_DRIVE",
    "RDP_SMARTCARD",
    "RDP_AUDIO_OUTPUT",
    "SSH_SHELL_SESSION",
    "SSH_REMOTE_COMMAND",
    "SSH_SCP_UP",
    "SSH_SCP_DOWN",
    "SFTP_SESSION",
  ]
}