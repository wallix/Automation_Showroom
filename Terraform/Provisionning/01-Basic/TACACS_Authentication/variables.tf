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

## TACACS+ server

variable "tacacs_host" {
  description = "IP address or FQDN of the TACACS+ server."
  type        = string
  default     = "192.0.2.40"
}

variable "tacacs_secret" {
  description = "TACACS+ shared secret configured for the Bastion on the server. Set it with TF_VAR_tacacs_secret."
  type        = string
  sensitive   = true
}

## Bastion side

variable "user_name" {
  description = "Login of the Bastion user, checked by the TACACS+ server. null: <prefix>-jdoe."
  type        = string
  default     = null
}
