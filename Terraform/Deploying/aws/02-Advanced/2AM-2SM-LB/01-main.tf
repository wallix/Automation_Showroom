terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.85.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.3"
    }
    http = {
      source  = "hashicorp/http"
      version = ">=3.4.5"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.5.2"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.6"
    }
  }
}

// Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
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
  count    = var.number_of_sm == 2 ? 1 : 0
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