##########################
# Configuration of users #
##########################
resource "wallix-bastion_user" "Demo_Users" {
  for_each = local.yaml_inventory["users_inventory"]

  user_name        = each.value["user_name"]
  display_name     = each.value["display_name"]
  email            = each.value["email"]
  profile          = each.value["profile"]
  user_auths       = each.value["user_auths"]
  password         = random_password.primary_accounts[each.key].result
  force_change_pwd = each.value["force_change_pwd"]
  ssh_public_key   = each.value["ssh_public_key"]
}

##############################
# Configure a group of users #
##############################
resource "wallix-bastion_usergroup" "Demo_User_Groups" {
  # Iterate on all users
  for_each = {
    for user_key, user_value in wallix-bastion_user.Demo_Users : user_key => user_value
  }
  # group creation
  group_name = each.value.user_name
  timeframes = ["allthetime"]

  # put users in groups
  users = [each.value.user_name]
}
