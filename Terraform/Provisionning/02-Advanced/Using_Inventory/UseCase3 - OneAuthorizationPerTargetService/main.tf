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

locals {
  inventory = yamldecode(file("${path.module}/data_input/inventory.yaml"))
  users     = local.inventory.users_inventory
  vms       = local.inventory.vms_inventory

  # One entry per account of each server, keyed "<server name>_<account>" like the user groups.
  vm_accounts = {
    for entry in flatten([
      for vm_key, vm in local.vms : [
        for account in vm.accounts : { key = "${vm.name}_${account}", vm = vm_key, account = account }
      ]
    ]) : entry.key => entry
  }

  # Subprotocols enabled on the services, per protocol.
  subprotocols = {
    SSH = ["SSH_SHELL_SESSION", "SSH_REMOTE_COMMAND", "SSH_SCP_UP", "SSH_SCP_DOWN", "SFTP_SESSION"]
    RDP = ["RDP_CLIPBOARD_UP", "RDP_CLIPBOARD_DOWN", "RDP_CLIPBOARD_FILE", "RDP_PRINTER", "RDP_COM_PORT", "RDP_DRIVE", "RDP_SMARTCARD", "RDP_AUDIO_OUTPUT"]
  }
}
