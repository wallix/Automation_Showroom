variable "product_name" {
  description = "Specifies the product to deploy: bastion / access-manager"
  type        = string
}
variable "product_version" {
  description = "Specifies the version of the bastion or access-manager"
  type        = string
}
variable "allowed_ip" {
  description = "Specifies the ip allowed to access the instance."
  type        = string
}

variable "aws_region" {
  description = "Specifies the aws region to use."
  type        = string
}
variable "aws_instance_size" {
  description = "Specifies the instance sizing."
  type        = string
  default     = "t2.small"
}
variable "aws_key_name" {
  description = "Specifies the ssh key name that will be use to access VM after deployment."
  type        = string
}
variable "aws_vpc_id" {
  description = "Specifies the vpc in which the VM will be deployed."
  type        = string
}
