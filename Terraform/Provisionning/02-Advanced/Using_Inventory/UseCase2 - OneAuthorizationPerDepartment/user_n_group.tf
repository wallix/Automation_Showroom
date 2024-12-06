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
  depends_on = [wallix-bastion_user.Demo_Users]
  # Iterate on all users
  for_each = {
    for group, users in local.yaml_inventory["group_inventory"] :
    group => {
      group_name = group
      users      = [for user in users : local.yaml_inventory["users_inventory"][user].user_name]
    }
  }

  # group creation
  group_name = each.value.group_name
  timeframes = ["allthetime"]

  # put users in groups
  users = each.value.users
}
