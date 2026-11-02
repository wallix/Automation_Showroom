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
  description = "Version of the REST API. OIDC requires v3.12."
  type        = string
  default     = "v3.12"
}

variable "bastion_info_insecure_skip_verify" {
  description = "Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate."
  type        = bool
  default     = false
}

## Identity provider

variable "oidc_name" {
  description = "Name of the OIDC external authentication on the Bastion."
  type        = string
  default     = "corporate_oidc"
}

variable "oidc_discovery_url" {
  description = "URL of the OpenID Provider metadata, ending with /.well-known/openid-configuration."
  type        = string
}

variable "oidc_client_id" {
  description = "Client ID of the Bastion, registered on the identity provider."
  type        = string
}

variable "oidc_client_secret" {
  description = "Client secret of the Bastion. Ephemeral: never written to the state or a plan file."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "oidc_client_secret_version" {
  description = "Increase it to send a new oidc_client_secret to the Bastion (rotation)."
  type        = number
  default     = 1
}

variable "oidc_scopes" {
  description = "Scopes requested from the identity provider."
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "oidc_claims" {
  description = "Claims of the ID token holding the user attributes. group is needed for the group mappings."
  type = object({
    username    = string
    group       = optional(string)
    email       = optional(string)
    displayname = optional(string)
  })
  default = {
    username    = "preferred_username"
    group       = "groups"
    email       = "email"
    displayname = "name"
  }
}

## Bastion side

variable "authdomain" {
  description = "OIDC authentication domain. label is shown on the login page; default_language is one of de, en, es, fr, ru."
  type = object({
    domain_name          = string
    auth_domain_name     = string
    label                = string
    default_email_domain = string
    default_language     = optional(string, "en")
  })
}

variable "group_mappings" {
  description = "Bastion user group => identity provider group (group claim value) and Bastion profile."
  type = map(object({
    idp_group = string
    profile   = optional(string, "user")
  }))
  default = {
    "OIDC_Administrators" = { idp_group = "bastion-admins", profile = "product_administrator" }
    "OIDC_Users"          = { idp_group = "bastion-users" }
  }
}
