terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

provider "wallix-bastion" {
  ip                   = var.bastion_info_ip
  port                 = var.bastion_info_port
  user                 = var.bastion_info_user
  token                = var.bastion_info_token
  password             = var.bastion_info_password
  api_version          = var.bastion_info_api_version
  insecure_skip_verify = var.bastion_info_insecure_skip_verify
}

resource "random_pet" "demo" {
  prefix = "sshca"
}

locals {
  # Every object name starts with this random prefix, so several people can run the example on the same Bastion.
  name = random_pet.demo.id
}
