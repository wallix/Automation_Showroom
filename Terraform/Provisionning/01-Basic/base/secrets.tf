resource "random_pet" "demo" {
  prefix = "demo"
}

# Password of the Bastion user (web UI and SSH proxy login).
resource "random_password" "user" {
  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

# Password stored in the Bastion vault for the target account. A real server needs its real password.
resource "random_password" "target_account" {
  length           = 20
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_%@+-."
}

# SSH key pair of the Bastion user: the public key goes to the Bastion, the private key to a local file.
resource "tls_private_key" "user" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "user_private_key" {
  content         = tls_private_key.user.private_key_openssh
  filename        = "${path.module}/${local.name}.pem"
  file_permission = "0600"
}
