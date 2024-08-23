
// Generates a secure private key for SSH connection to instances
resource "tls_private_key" "key_pair" {
  algorithm = "ED25519"

}

// Create the Key Pair on AWS
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.key_pair.public_key_openssh

}