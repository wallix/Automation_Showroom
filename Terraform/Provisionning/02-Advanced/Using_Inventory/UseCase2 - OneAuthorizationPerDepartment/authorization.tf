# One authorization per department: its user group on the target group of the same name.
resource "wallix-bastion_authorization" "departments" {
  for_each = wallix-bastion_usergroup.departments

  authorization_name = each.value.group_name
  user_group         = each.value.group_name
  target_group       = wallix-bastion_targetgroup.departments[each.key].group_name
  authorize_sessions = true
  is_critical        = true
  is_recorded        = true
  subprotocols       = concat(["RDP"], local.subprotocols.RDP, local.subprotocols.SSH)
}
