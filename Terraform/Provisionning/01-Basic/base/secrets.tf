# Generate SSH Key
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# write local file
resource "local_file" "private_key" {
  content         = tls_private_key.rsa-4096.private_key_pem
  filename        = "ssh_private_key.pem"
  file_permission = "0600"
}

# Generate a random Password
resource "random_string" "demo" {
  length           = 16
  special          = true
  min_special      = 2
  min_upper        = 2
  min_numeric      = 2
  override_special = "_%@|/"
}

resource "random_pet" "user" {
  prefix = "demo"
}

resource "random_pet" "group" {
  prefix = "demo"
}