################################################################################################
#   Here you will find the configuration for Autorization. If you need more options, please   #
#   refer to: https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs        #
################################################################################################

### AUTORIZATIONS ###
resource "wallix-bastion_authorization" "Demo_UseCase2_Autorizations" {
  depends_on = [
    wallix-bastion_targetgroup.Demo_UseCase2_Target_Groups
  ]
  for_each           = wallix-bastion_usergroup.Demo_UseCase2_User_Groups
  authorization_name = each.value.group_name
  user_group         = each.value.group_name
  target_group       = each.value.group_name
  authorize_sessions = true
  is_critical        = true
  is_recorded        = true
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
