// MISC
variable "aws_profile" {
  default     = "default"
  type        = string
  description = "AWS profile to use!"
}

variable "project_name" {
  description = "Specifies the project name"
  type        = string
}

variable "ami-from-aws-marketplace" {
  type        = bool
  default     = true
  description = "Should we use the marketplace image ? If false, the shared image by WALLIX will be use."
}

variable "tags" {
  default     = {}
  description = "Map of tags to apply on resources."
  type        = map(string)
}

variable "aws-region" {
  type        = string
  description = "Aws region to deploy resources"
}

variable "key_pair_name" {
  description = "Name of the key pair that will be use to connect to the instance."
  type        = string
}

// Booleans

variable "alb_internal" {
  description = "Should Application Load Balancer be internal ?"
  default     = false
  type        = bool
}

variable "nlb_internal" {
  description = "Should Network Load Balancer be internal ?\n Setting it to false is risky."
  default     = true
  type        = bool
}

variable "deploy-integration-debian" {
  description = "Should a debian instance for integration be deployed ?"
  default     = true
  type        = bool
}

// AWS Networking

variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16"
  type        = string
}

variable "allowed_ips" {
  description = "Specifies the ips/networks allowed to access integration instance. e.g: [''10.0.0.0/16'',''90.15.25.21/32''] "
  type        = list(any)
  validation {
    condition     = (contains(var.allowed_ips, "127.0.0.1/32") == false)
    error_message = "Please change this range to a valid value. 0.0.0.0/0 is not recommanded"
  }
}

// Instance Sizing

variable "aws_instance_size_am" {
  default     = "t2.medium"
  description = "Specifies the instance sizing."
  type        = string
}

variable "aws_instance_size_sm" {
  default     = "t2.medium"
  description = "Specifies the instance sizing."
  type        = string
}

variable "aws_instance_size_debian" {
  default     = "t3.medium"
  description = "Specifies the instance sizing."
  type        = string
}
variable "am_disk_size" {
  default     = 30
  description = "AM disk sizing"
  type        = number
}

variable "am_disk_type" {
  default     = "gp3"
  description = "AM disk type"
  type        = string
}

variable "sm_disk_size" {
  default     = 31
  description = "SM disk sizing"
  type        = number
}

variable "sm_disk_type" {
  default     = "gp3"
  description = "SM disk type"
  type        = string
}

variable "bastion-version" {
  type        = string
  default     = ""
  description = "Bastion version to use. It can be partial or full value (5, 4.0 , 4.4.1, 4.4.1.8).\n Can be empty for latest pushed image."
}

variable "access-manager-version" {
  type        = string
  default     = ""
  description = "Bastion version to use. It can be partial or full value (12, 11.0 , 10.4.3, 10.0.7.28).\n Can be empty for latest pushed image."
}

variable "number-of-am" {
  type        = number
  default     = 2
  description = "Number of AM to be deployed"
  validation {
    condition     = (var.number-of-am <= 3)
    error_message = "Value should be between 0 and 3 !"
  }
}

variable "number-of-sm" {
  type        = number
  default     = 2
  description = "Number of SM to be deployed"
  validation {
    condition     = (var.number-of-sm <= 3)
    error_message = "Value should be between 0 and 3 !"
  }
}
