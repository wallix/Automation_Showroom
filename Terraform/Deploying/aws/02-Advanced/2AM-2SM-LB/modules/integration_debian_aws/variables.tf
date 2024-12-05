variable "allowed_ips" {
  default     = ["127.0.0.1/32"]
  description = "Specifies the ips/networks allowed to access integration instance. e.g: [''10.0.0.0/16'',''90.15.25.21/32''] "
  type        = list(string)
  validation {
    condition     = (contains(var.allowed_ips, "127.0.0.1/32") == false)
    error_message = "Please change this range to a valid value. 0.0.0.0/0 is not recommanded"
  }
}

variable "debian_version" {
  default     = 12
  description = "version debian to use. 11, 12."
  type        = number
}

variable "aws_instance_size" {
  default     = "t3.medium"
  description = "Specifies the instance sizing."
  type        = string
}

variable "common_tags" {
  default     = {}
  description = "Map of tags to apply on instances resources."
  type        = map(string)
}

variable "key_pair_name" {
  description = "Name of the key pair that will be use to connect to the instance."
  type        = string
}

variable "private_key" {
  description = "Private key to be added in /home/admin/.ssh/ to connect to WALLIX Instances."
  type        = string
}

variable "public_ssh_key" {
  description = "Public key to be added in /home/rdpuser/.ssh/authorized_keys."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Will be used for Naming and Tags."
  type        = string
}

variable "sm-instances" {
  description = "list of SM IP or Network in CIDR Format."
  type        = list(string)
}

variable "am-instances" {
  description = "list of AM IP or Network in CIDR Format."
  type        = list(string)
}

variable "subnet_id" {
  description = "ID of the subnet to use for this instance"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Map of tags to apply on instances resources."
  type        = map(string)
}
variable "vpc_id" {
  description = "vpc_id to which attach the security group"
  type        = string
}
