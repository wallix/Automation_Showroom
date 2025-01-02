# Create lists to iterate on all users
locals {
  primary_accounts = {
    for user_key, user in local.yaml_inventory["users_inventory"] :
    user_key => "${user_key}-primary-password"
  }

  secondary_accounts = flatten([
    for vm_key, vm in local.yaml_inventory["vms_inventory"] : [
      for account in vm.accounts : "${vm_key}-${account}-password" # For password it's better to use "-" separtor if you want to store them in Azure Vault 
    ]
  ])
}


### Generate primary_accounts passwords
resource "random_password" "primary_accounts" {
  for_each         = local.primary_accounts
  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
  override_special = "_@+.-"
}

### Generate secondary_accounts passwords
resource "random_password" "secondary_accounts" {
  for_each         = toset(local.secondary_accounts)
  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
  override_special = "_@+.-"
}
