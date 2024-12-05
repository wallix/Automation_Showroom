# Create lists to iterate on all users
locals {
  primary_accounts = {
    for user_key, user in local.yaml_inventory["users_inventory"] :
    user["user_name"] => "${user["user_name"]}-primary-password"
  }

  secondary_accounts = {
    for user_key, user in local.yaml_inventory["users_inventory"] :
    user["user_name"] => "${user["user_name"]}-target-password"
  }

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
  for_each         = local.secondary_accounts
  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
  override_special = "_@+.-"
}


# # Generate SSH Key
# resource "tls_private_key" "rsa-4096" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
# # write local file
# resource "local_file" "private_key" {
#   content         = tls_private_key.rsa-4096.private_key_pem
#   filename        = "ssh_private_key.pem"
#   file_permission = "0600"
# }
