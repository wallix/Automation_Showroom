resource "wallix-bastion_user" "users" {
  for_each = local.users

  user_name        = each.value.user_name
  display_name     = each.value.display_name
  email            = each.value.email
  profile          = each.value.profile
  user_auths       = each.value.user_auths
  password         = random_password.users[each.key].result
  force_change_pwd = each.value.force_change_pwd
  ssh_public_key   = each.value.ssh_public_key
}

# One user group per department.
resource "wallix-bastion_usergroup" "departments" {
  for_each = local.inventory.user_group_inventory

  group_name = each.key
  timeframes = ["allthetime"]
  users      = [for user in each.value : wallix-bastion_user.users[user].user_name]
}
