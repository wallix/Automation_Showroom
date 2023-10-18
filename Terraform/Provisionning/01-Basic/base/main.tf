terraform {
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = ">=0.12.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "wallix-bastion" {
  ip          = var.bastion_info_ip
  token       = var.bastion_info_token
  api_version = var.bastion_info_api_version
  user        = var.bastion_info_user
  port        = var.bastion_info_port
}

data "wallix-bastion_version" "version" {}


