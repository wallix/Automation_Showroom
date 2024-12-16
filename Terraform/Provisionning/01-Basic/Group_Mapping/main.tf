terraform {
  required_version = ">=v1.10.1"
  required_providers {
    wallix-bastion = {
      source  = "wallix/wallix-bastion"
      version = ">=0.14.1"
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
# Set locals
locals {
  input_data        = jsondecode(file("input_data.json"))
  mailNickname_list = local.input_data[*].mailNickname
  id_list           = local.input_data[*].id
  group_map         = zipmap(local.mailNickname_list, local.id_list)

}

# Configure a group of users
resource "wallix-bastion_usergroup" "demo" {
  for_each   = toset(local.mailNickname_list)
  group_name = each.key
  profile    = lookup(var.profil_mapping, each.key, "user")
  timeframes = ["allthetime"]
}

# Configure a group mapping
resource "wallix-bastion_authdomain_mapping" "test" {
  for_each       = toset(keys(wallix-bastion_usergroup.demo))
  domain_id      = var.authdomain_id
  user_group     = each.value
  external_group = local.group_map[each.value]
}