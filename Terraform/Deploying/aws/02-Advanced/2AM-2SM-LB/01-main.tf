terraform {
  // This module will only work with Terraform > 1.9.4.
  required_version = ">= 1.9.0"
}

// Configure the AWS Provider
provider "aws" {
  region = var.aws-region
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

module "cloud-init-sm" {
  source                        = "./modules/cloud-init-wallix"
  set_service_user_password     = true
  use_of_lb                     = true
  http_host_trusted_hostnames   = aws_lb.front_sm.dns_name
  set_webui_password_and_crypto = true

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

resource "local_sensitive_file" "replication_master" {
  count    = var.number-of-sm == 2 ? 1 : 0
  filename = "info_replication.txt"
  content = templatefile("${path.module}/info_replication_master_master.tpl", {
    wabadmin_password  = module.cloud-init-sm.wallix_password_wabadmin,
    wabsuper_password  = module.cloud-init-sm.wallix_password_wabsuper,
    cryptokey_password = module.cloud-init-sm.wallix_crypto,
    webui_password     = module.cloud-init-sm.wallix_password_webui,
    ip1                = module.instance_bastion[0].instance_private_ip,
    ip2                = module.instance_bastion[1].instance_private_ip
    }
  )
}