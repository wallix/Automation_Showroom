variable "to_gzip" {
  default     = false
  description = "Should the user-data be compressed ?"
  type        = bool
}

variable "to_base64_encode" {
  default     = false
  description = "Should the user-data be encoded in base64?"
  type        = bool
}

variable "set_service_user_password" {
  default     = false
  description = "Should we changepasswd for WALLIX Service user ?\n ( Wabadmin, Wabsuper, Wabupgrade)"
  type        = bool
}

variable "use_of_lb" {
  default     = false
  description = "Are you going to use a loadbalancer ?"
  type        = bool
}

variable "http_host_trusted_hostnames" {
  default     = ""
  description = "fqdn of the loadbalancers which will be added to http_host_trusted_hostnames.\n If muliple values, should be separated by a comma."
  type        = string
  validation {
    condition     = (var.use_of_lb == true && var.http_host_trusted_hostnames != "") || (var.use_of_lb == false && var.http_host_trusted_hostnames == "")
    error_message = "If use_of_lb is true, please provide http_host_trusted_hostnames"
  }

}

variable "set_webui_password_and_crypto" {
  default     = false
  description = " !!! Session Manager Only !!!\nShould we change password for WebUI Admin and set encryption key?"
  type        = bool
}