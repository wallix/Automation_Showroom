terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = "~> 0.17.0"
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
  # Output of `az ad group list`, keyed by mailNickname (becomes the Bastion user group name).
  entra_groups = { for group in jsondecode(file(var.input_file)) : group.mailNickname => group }
}

# Existing Entra ID authentication domain, looked up by name.
data "wallix-bastion_authdomain_azuread" "entra" {
  domain_name = var.authdomain_name
}

resource "wallix-bastion_usergroup" "entra" {
  for_each = local.entra_groups

  group_name  = each.key
  description = try(each.value.description, null)
  # Profile given to the users who log in through the mapping.
  profile    = lookup(var.profile_mapping, each.key, "user")
  timeframes = ["allthetime"]
}

# A member of the Entra ID group gets the Bastion user group at login.
resource "wallix-bastion_authdomain_mapping" "entra" {
  for_each = wallix-bastion_usergroup.entra

  domain_id      = data.wallix-bastion_authdomain_azuread.entra.id
  user_group     = each.value.group_name
  external_group = local.entra_groups[each.key].id # Object ID of the Entra ID group.
}
