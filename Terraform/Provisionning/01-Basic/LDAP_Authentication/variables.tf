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

## LDAP directory

variable "ldap_host" {
  description = "IP address or FQDN of the LDAP server."
  type        = string
  default     = "ldap.example.com"
}

variable "ldap_port" {
  description = "LDAPS port of the LDAP server."
  type        = number
  default     = 636
}

variable "ldap_ca_file" {
  description = "PEM file of the CA that signed the LDAP server certificate. null: no CA sent to the Bastion."
  type        = string
  default     = null
}

variable "ldap_base" {
  description = "Base DN where the Bastion searches the users."
  type        = string
  default     = "ou=people,dc=example,dc=com"
}

variable "ldap_bind_dn" {
  description = "DN of the service account the Bastion binds with."
  type        = string
  default     = "cn=bastion,ou=services,dc=example,dc=com"
}

variable "ldap_bind_password" {
  description = "Password of the bind account. Set it with TF_VAR_ldap_bind_password."
  type        = string
  sensitive   = true
}

## Bastion side

variable "auth_domain_name" {
  description = "Name of the directory domain (auth_domain_name of the Bastion domain)."
  type        = string
  default     = "example.com"
}

variable "ldap_group_dn" {
  description = "DN of the LDAP group whose members get the Bastion user group."
  type        = string
  default     = "cn=bastion-users,ou=groups,dc=example,dc=com"
}
