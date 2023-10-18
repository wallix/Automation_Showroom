## Wallix-Bastion provider

variable "bastion_info_ip" {
  description = "IP of the bastion"
  type        = string
}
variable "bastion_info_token" {
  sensitive   = true
  description = "This is the token to authenticate on bastion API."
  type        = string
}
variable "bastion_info_api_version" {
  description = "This is the version of api used to call api."
  default     = "v3.3"
  type        = string
}
variable "bastion_info_user" {
  description = "This is the username used to authenticate on bastion API."
  default     = "admin"
  type        = string

}
variable "bastion_info_port" {
  description = "This is the tcp port for https connection on bastion API."
  default     = "443"
  type        = string

}