
# Authorization
### USERS

resource "wallix-bastion_authorization" "Demo_UseCase1_Autorizations" {
  depends_on = [
    wallix-bastion_usergroup.Demo_UseCase1_User_Groups,
    wallix-bastion_targetgroup.Demo_UseCase1_Target_Groups
  ]
  for_each           = wallix-bastion_user.Demo_UseCase1_Users
  authorization_name = each.value.user_name
  user_group         = each.value.user_name
  target_group       = each.value.user_name
  authorize_sessions = true
  is_critical        = true
  subprotocols = [
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
