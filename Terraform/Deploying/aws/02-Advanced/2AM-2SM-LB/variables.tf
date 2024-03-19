variable "project_name" {
  description = "Specifies the version of the bastion or access-manager"
  type        = string
  default     = "Wallix_Lab"
}

variable "project_owner" {
  description = "Specifies the Project Owner name : very useful for FinOps"
  type        = string
}

variable "bastion_version" {
  description = "Specifies the version of the bastion or access-manager"
  type        = string
}

variable "acces_manager_version" {
  description = "Specifies the version of the bastion or access-manager"
  type        = string
}

variable "allowed_ips" {
  description = "Specifies the ips/networks allowed to access integration instance. e.g: [''10.0.0.0/16'',''90.15.25.21/32''] "
  type        = list(any)
}

variable "aws_region" {
  description = "Specifies the aws region to use."
  type        = string
}

variable "aws_instance_size_am" {
  description = "Specifies the instance sizing."
  type        = string
  default     = "t3.xlarge"
}

variable "aws_instance_size_sm" {
  description = "Specifies the instance sizing."
  type        = string
  default     = "t3.xlarge"
}

variable "aws_instance_size_debian" {
  description = "Specifies the instance sizing."
  type        = string
  default     = "t3.large"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16"
  type        = string
}

variable "primary_az" {
  description = "Specifies the primary Availability Zone to use."
  type        = string
}

variable "secondary_az" {
  description = "Specifies the secondary Availability Zone to use."
  type        = string
}

variable "subnet_az1_AM" {
  description = "A map of availability zones to CIDR blocks, which will be set up as subnets."
  type        = string
}

variable "subnet_az2_AM" {
  description = "A map of availability zones to CIDR blocks, which will be set up as subnets."
  type        = string
}

variable "subnet_az1_SM" {
  description = "A map of availability zones to CIDR blocks, which will be set up as subnets."
  type        = string
}

variable "subnet_az2_SM" {
  description = "A map of availability zones to CIDR blocks, which will be set up as subnets."
  type        = string
}


variable "am_disk_size" {
  description = "AM disk sizing"
  type        = number
  default     = 10
}

variable "am_disk_type" {
  description = "AM disk sizing"
  type        = string
  default     = "gp3"
}


variable "sm_disk_size" {
  description = "AM disk sizing"
  type        = number
  default     = 10
}

variable "sm_disk_type" {
  description = "AM disk sizing"
  type        = string
  default     = "gp3"
}