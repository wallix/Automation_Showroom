## Connection to the Bastion REST API (same variables in every example)

variable "bastion_info_ip" {
  description = "IP address or FQDN of the Bastion."
  type        = string
}

variable "bastion_info_port" {
  description = "HTTPS port of the Bastion REST API."
  type        = number
  default     = 443
}

variable "bastion_info_user" {
  description = "Bastion user that owns the API key (or logs in with bastion_info_password)."
  type        = string
  default     = "admin"
}

variable "bastion_info_token" {
  description = "API key of bastion_info_user. Set this or bastion_info_password, preferably with TF_VAR_bastion_info_token."
  type        = string
  sensitive   = true
  default     = null
}

variable "bastion_info_password" {
  description = "Password of bastion_info_user, when no API key is used."
  type        = string
  sensitive   = true
  default     = null
}

variable "bastion_info_api_version" {
  description = "Version of the REST API: v3.12, or v3.8 for an older Bastion."
  type        = string
  default     = "v3.12"
}

variable "bastion_info_insecure_skip_verify" {
  description = "Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate."
  type        = bool
  default     = false
}

## Example inputs

variable "authdomain_name" {
  description = "Domain name of the Entra ID authentication domain that already exists on the Bastion."
  type        = string
}

variable "input_file" {
  description = "JSON export of the Entra ID groups (az ad group list --output json)."
  type        = string
  default     = "input_data.json"
}

variable "profile_mapping" {
  description = "Bastion profile per group (mailNickname). The profile must exist on the Bastion; unlisted groups get \"user\"."
  type        = map(string)
  default = {
    "PAM_Approver"                = "approver"
    "PAM_Auditor"                 = "auditor"
    "PAM_Operation_Administrator" = "operation_administrator"
    "PAM_System_Administrator"    = "system_administrator"
    "PAM_User"                    = "user"
  }
}
