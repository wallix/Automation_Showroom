# Password of each user on the Bastion.
resource "random_password" "users" {
  for_each = local.users

  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_@+.-"
}

# Placeholder password of each RDP account, stored in the Bastion vault: set the real ones.
resource "random_password" "accounts" {
  for_each = { for k, a in local.vm_accounts : k => a if local.vms[a.vm].service == "RDP" }

  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_@+.-"
}
