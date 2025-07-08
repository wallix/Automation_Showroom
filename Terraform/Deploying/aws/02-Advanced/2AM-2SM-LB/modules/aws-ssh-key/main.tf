terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.85.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.6"
    }
  }
}
// Generates a secure private key for SSH connection to instances
resource "tls_private_key" "key_pair" {
  algorithm = "ED25519"

}

// Create the Key Pair on AWS
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.key_pair.public_key_openssh

}