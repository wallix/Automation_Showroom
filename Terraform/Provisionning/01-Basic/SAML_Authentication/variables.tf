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
  description = "Version of the REST API. This example requires v3.12 (claim_customization)."
  type        = string
  default     = "v3.12"
}

variable "bastion_info_insecure_skip_verify" {
  description = "Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate."
  type        = bool
  default     = false
}

## Identity provider

variable "idp_metadata_file" {
  description = "SAML metadata (XML) of the identity provider, downloaded from it."
  type        = string
  default     = "idp-metadata.xml"
}

variable "saml_attributes" {
  description = "Attributes of the SAML assertion holding the user name, display name, email and groups."
  type = object({
    username    = string
    displayname = optional(string)
    email       = optional(string)
    group       = optional(string)
  })
  default = {
    username    = "username"
    displayname = "displayname"
    email       = "email"
    group       = "groups"
  }
}

## Bastion side

variable "auth_domain_name" {
  description = "Name of the corporate domain (auth_domain_name of the Bastion domain)."
  type        = string
  default     = "example.com"
}

variable "idp_group" {
  description = "Group, as sent by the identity provider in the group attribute, whose members get the Bastion user group."
  type        = string
  default     = "bastion-users"
}
