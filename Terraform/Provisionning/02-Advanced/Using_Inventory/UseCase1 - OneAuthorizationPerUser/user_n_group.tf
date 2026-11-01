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

# One user group per user, named after the user.
resource "wallix-bastion_usergroup" "users" {
  for_each = wallix-bastion_user.users

  group_name = each.value.user_name
  timeframes = ["allthetime"]
  users      = [each.value.user_name]
}
