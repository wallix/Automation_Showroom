terraform {
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = ">=0.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "wallix-bastion" {
  ip = var.bastion_info_ip
  #token       = var.bastion_info_token
  api_version = var.bastion_info_api_version
  user        = var.bastion_info_user
  password    = var.bastion_info_password
  port        = var.bastion_info_port
}

data "wallix-bastion_version" "version" {}


locals {
  yaml_inventory = yamldecode(file("./variables/inventory.yaml"))
}
