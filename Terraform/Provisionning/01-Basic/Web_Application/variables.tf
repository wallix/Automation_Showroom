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
  description = "Version of the REST API. Web applications require v3.12."
  type        = string
  default     = "v3.12"
}

variable "bastion_info_insecure_skip_verify" {
  description = "Skip the TLS certificate check. Only for a lab Bastion with a self-signed certificate."
  type        = bool
  default     = false
}

## Example inputs

variable "application_name" {
  description = "Name of the web application on the Bastion (also used for its target group and authorization)."
  type        = string
  default     = "intranet"
}

variable "application_url" {
  description = "URL the user's browser session opens."
  type        = string
}

variable "login_form_url" {
  description = "URL of the login page, for the automatic login. null: no automatic login."
  type        = string
  default     = null
}

variable "login_button_selector" {
  description = "CSS selector of the login button, e.g. #submit-button. Set it with login_form_url."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Global domain holding the account of the web application."
  type        = string
  default     = "webapps"
}

variable "webapp_account_login" {
  description = "Login of the account injected into the web application."
  type        = string
}

variable "webapp_account_password" {
  description = "Password of that account, stored in the Bastion vault (and in the Terraform state, as a sensitive value)."
  type        = string
  sensitive   = true
}

variable "users" {
  description = "Existing Bastion users allowed to open the web application."
  type        = list(string)
  default     = []
}
