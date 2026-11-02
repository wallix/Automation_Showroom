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

variable "smtp_server" {
  description = "IP address or FQDN of the SMTP relay."
  type        = string
}

variable "smtp_port" {
  description = "Port of the SMTP relay."
  type        = number
  default     = 587
}

variable "smtp_protocol" {
  description = "smtp, smtps or starttls."
  type        = string
  default     = "starttls"
}

variable "smtp_authentication_method" {
  description = "off (no authentication), on, plain, login, SCRAM-SHA-1, CRAM-MD5, DIGEST-MD5 or ntlm."
  type        = string
  default     = "off"
}

variable "smtp_user" {
  description = "User of the SMTP relay, when it requires authentication."
  type        = string
  default     = null
}

variable "smtp_password" {
  description = "Password of smtp_user. Set it with TF_VAR_smtp_password."
  type        = string
  sensitive   = true
  default     = null
}

variable "sender_name" {
  description = "Display name of the emails sent by the Bastion."
  type        = string
  default     = "WALLIX Bastion"
}

variable "sender_email" {
  description = "Sender address of the emails sent by the Bastion."
  type        = string
  default     = "bastion@example.com"
}

variable "postmaster_email" {
  description = "Address that receives the emails of the local services of the Bastion."
  type        = string
  default     = "postmaster@example.com"
}

variable "recipients" {
  description = "Addresses that receive the notification."
  type        = list(string)
  default     = ["secops@example.com"]
}

variable "events" {
  description = "Events that send the notification (names checked at plan, see the README)."
  type        = list(string)
  default     = ["wrong_fingerprint", "integrity_error", "filesystem_full", "licence_notifications"]
}
