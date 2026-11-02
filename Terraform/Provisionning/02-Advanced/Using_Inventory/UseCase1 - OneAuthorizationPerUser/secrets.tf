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

resource "random_password" "rds_account" {
  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_@+.-"
}

# Password of each user's account on the targets, stored in the Bastion vault.
resource "random_password" "accounts" {
  for_each = local.users

  length           = 16
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_@+.-"
}
