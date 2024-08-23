terraform {
  # This module was only being tested with Terraform 1.9.x. However, to make upgrading easier, we are setting 1.0.0 as the minimum version.
  required_version = ">= 1.0.0"
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws-region
}

module "cloud-init-sm" {
  source                      = "./modules/cloud-init-wallix"
  set_service_user_password   = true
  use_of_lb                   = true
  http_host_trusted_hostnames = aws_lb.front_sm.dns_name
}

module "cloud-init-am" {
  source                      = "./modules/cloud-init-wallix"
  use_of_lb                   = true
  set_service_user_password   = true
  http_host_trusted_hostnames = aws_lb.front_am.dns_name
}

module "ssh_aws" {
  source   = "./modules/aws-ssh-key"
  key_name = var.key_pair_name
}

resource "local_sensitive_file" "private_key" {
  content         = module.ssh_aws.ssh_private_key
  filename        = "private_key.pem"
  file_permission = "400"

}