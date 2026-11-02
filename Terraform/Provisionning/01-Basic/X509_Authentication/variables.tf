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

## Certificates

variable "bastion_certificate_file" {
  description = "PEM certificate of the Bastion web and API listener (replaces the current one)."
  type        = string
  default     = "bastion.crt"
}

variable "bastion_private_key_file" {
  description = "PEM private key of that certificate."
  type        = string
  default     = "bastion.key"
}

variable "users_ca_file" {
  description = "PEM certificate of the CA that issues the user certificates."
  type        = string
  default     = "users-ca.pem"
}

## Revocation check

variable "crl_url" {
  description = "URL the Bastion downloads the CRL of the users CA from. It must be reachable from the Bastion."
  type        = string
  default     = "http://pki.example.com/users-ca.crl"
}

variable "ocsp_responder" {
  description = "OCSP responder of the users CA."
  type        = string
  default     = "http://ocsp.example.com"
}

## Bastion side

variable "user_certificate_dn" {
  description = "Subject DN of the certificate of the Bastion user."
  type        = string
  default     = "CN=jdoe,OU=Users,O=Example,C=FR"
}
