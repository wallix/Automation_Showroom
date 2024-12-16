## Wallix-Bastion provider

variable "bastion_info_ip" {
  description = "IP of the bastion"
  type        = string
}
variable "bastion_info_token" {
  sensitive   = true
  description = "This is the token to authenticate on bastion API."
  type        = string
}
variable "bastion_info_api_version" {
  description = "This is the version of api used to call api."
  default     = "v3.12"
  type        = string
}
variable "bastion_info_user" {
  description = "This is the username used to authenticate on bastion API."
  default     = "admin"
  type        = string

}
variable "bastion_info_port" {
  description = "This is the tcp port for https connection on bastion API."
  default     = "443"
  type        = string

}

variable "authdomain_id" {
  description = "Id of the authdomain were mapping will be created!"
  type        = string
}

variable "profil_mapping" {
  description = "Map value of the user_group name and the profil to set. Profil must exist on bastion. By default user will be use"
  type        = map(string)
  default = {
    "PAM_Approver_EntraID_Group"  = "approver",
    "PAM_Auditor_EntraIDGroup"    = "product_administrator",
    "PAM_Operation_Administrator" = "operation_administrator",
    "PAM_System_Administrator"    = "system_administrator",
    "PAM_User"                    = "user"
  }
}