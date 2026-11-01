variable "product_name" {
  description = "Product to deploy: bastion or access-manager."
  type        = string

  validation {
    condition     = contains(["bastion", "access-manager"], var.product_name)
    error_message = "product_name must be \"bastion\" or \"access-manager\"."
  }
}

variable "product_version" {
  description = "Full product version, as found in the AMI name (<product_name>-<product_version>-aws)."
  type        = string
}

variable "allowed_ip" {
  description = "CIDR blocks allowed to reach the instance (HTTP/HTTPS, SSH admin on 2242, and SSH/RDP proxies for the Bastion). Use your own public IP as x.x.x.x/32; 0.0.0.0/0 exposes the instance to the whole Internet."
  type        = list(string)

  validation {
    condition     = length(var.allowed_ip) > 0 && alltrue([for cidr in var.allowed_ip : can(cidrnetmask(cidr))])
    error_message = "allowed_ip must contain at least one valid IPv4 CIDR block, e.g. [\"203.0.113.10/32\"]."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "aws_instance_size" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
}

variable "aws_key_name" {
  description = "Name of an existing EC2 key pair, used for SSH access to the instance."
  type        = string
}

variable "aws_vpc_id" {
  description = "ID of the existing VPC in which the subnet and the instance are created."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR of the subnet created for the instance. Must be a free range inside the VPC CIDR."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "Project_Owner" {
  description = "Value of the Project_Owner tag (e.g. an e-mail address), useful for cost tracking."
  type        = string
}

variable "Project_Name" {
  description = "Project name, used in resource names and in the Project_Name tag."
  type        = string
}
