//TODO: document the variables
variable "to_gzip" {
  type    = bool
  default = false
}

variable "to_base64_encode" {
  type    = bool
  default = false
}

variable "set_service_user_password" {
  type    = bool
  default = false
}

variable "use_of_lb" {
  type    = bool
  default = false
}

variable "http_host_trusted_hostnames" {
  default     = ""
  type        = string
  description = "fqdn of the loadbalancers"
  validation {
    condition     = (var.use_of_lb == true && var.http_host_trusted_hostnames != "") || (var.use_of_lb == false && var.http_host_trusted_hostnames == "")
    error_message = "If use_of_lb is true, please provide http_host_trusted_hostnames"
  }

}