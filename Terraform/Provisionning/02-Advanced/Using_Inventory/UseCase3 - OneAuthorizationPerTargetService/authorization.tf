# One authorization per access rule: its user group on the target group of the same name.
resource "wallix-bastion_authorization" "rules" {
  for_each = wallix-bastion_usergroup.rules

  authorization_name = each.value.group_name
  user_group         = each.value.group_name
  target_group       = wallix-bastion_targetgroup.accounts[each.key].group_name
  authorize_sessions = true
  is_critical        = true
  is_recorded        = true
  subprotocols       = concat(["RDP"], local.subprotocols.RDP, local.subprotocols.SSH)
}
