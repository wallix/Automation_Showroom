######################################################################################################
#   Here you will find the configuration for users and usergroups. If you need more options, please  # 
#   refer to: https://registry.terraform.io/providers/wallix/wallix-bastion/latest/docs              #
######################################################################################################

### USERS ###
# Configuration of users
resource "wallix-bastion_user" "Demo_UseCase3_Users" {
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

### USER GROUPS ###
# Configure a group of users 
resource "wallix-bastion_usergroup" "Demo_UseCase3_User_Groups" {
  depends_on = [wallix-bastion_user.Demo_UseCase3_Users]
  # Iterate through each group and its corresponding users in the YAML inventory
  for_each = {
    for group, users in local.yaml_inventory["user_group_inventory"] :
    group => {
      group_name = group                                                                         # Corresponds to the key of each iteration in user_group_inventory 
      users      = [for user in users : local.yaml_inventory["users_inventory"][user].user_name] # list of users in each group in user_group_inventory
    }
  }

  # Set the group name
  group_name = each.value.group_name
  timeframes = ["allthetime"]

  # Assign users to the current group
  users = each.value.users
}
