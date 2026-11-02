# One authorization per user: the user's group on the user's target group.
resource "wallix-bastion_authorization" "users" {
  for_each = wallix-bastion_usergroup.users

  authorization_name = each.value.group_name
  user_group         = each.value.group_name
  target_group       = wallix-bastion_targetgroup.users[each.key].group_name
  authorize_sessions = true
  is_critical        = true
  is_recorded        = true
  # RDP opens the sessions of the applications too.
  subprotocols = concat(["RDP"], local.subprotocols.RDP, local.subprotocols.SSH)
}
