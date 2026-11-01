# One Bastion user group per identity provider group: membership and profile are given at each login.
resource "wallix-bastion_usergroup" "idp" {
  for_each = var.group_mappings

  group_name  = each.key
  description = "Members of the IdP group ${each.value.idp_group}"
  profile     = each.value.profile
  timeframes  = ["allthetime"]
}

resource "wallix-bastion_authdomain_mapping" "idp" {
  for_each = var.group_mappings

  domain_id      = wallix-bastion_authdomain_oidc.idp.id
  user_group     = wallix-bastion_usergroup.idp[each.key].group_name
  external_group = each.value.idp_group # Value of the group claim, as sent by the identity provider.
}
