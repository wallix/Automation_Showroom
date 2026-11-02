// MISC
variable "aws_profile" {
  default     = "default"
  type        = string
  description = "AWS profile to use!"
}

variable "project_name" {
  description = "Specifies the project name. Load balancer and target group names derive from it and are limited to 32 characters."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,15}[A-Za-z0-9])?$", var.project_name))
    error_message = "project_name must be 1 to 17 characters: letters, digits and inner hyphens only (AWS load balancer naming rules)."
  }
}

variable "ami_from_aws_marketplace" {
  type        = bool
  default     = true
  description = "Should we use the marketplace image ? If false, the shared image by WALLIX will be use."
}

variable "tags" {
  default     = {}
  description = "Map of tags to apply on resources."
  type        = map(string)
}

variable "aws_region" {
  type        = string
  description = "Aws region to deploy resources"
}

variable "key_pair_name" {
  description = "Name of the key pair that will be use to connect to the instance."
  type        = string
}

// Booleans

variable "alb_internal" {
  description = "Should Application Load Balancer be internal ?\n If false, the AM web UI is reachable from allowed_ips over the Internet."
  default     = false
  type        = bool
}

variable "nlb_internal" {
  description = "Should Network Load Balancer be internal ?\n Setting it to false is risky."
  default     = true
  type        = bool
}

variable "deploy_integration_debian" {
  description = "Should a debian instance for integration be deployed ?"
  default     = true
  type        = bool
}

// AWS Networking

variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16. Prefix between /16 and /22 (subnets use 6 extra bits)."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && try(tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 22, false)
    error_message = "vpc_cidr must be a valid IPv4 CIDR block with a prefix between /16 and /22."
  }
}

variable "allowed_ips" {
  description = "Public CIDR blocks allowed to reach the ALB, the NLB and the integration instance, e.g: [\"203.0.113.10/32\"]. The VPC CIDR is always allowed on the load balancers."
  type        = list(string)
  validation {
    condition     = length(var.allowed_ips) > 0 && alltrue([for cidr in var.allowed_ips : can(cidrnetmask(cidr))]) && !contains(var.allowed_ips, "127.0.0.1/32")
    error_message = "allowed_ips must hold valid IPv4 CIDR blocks. Replace the 127.0.0.1/32 placeholder with your public IP (x.x.x.x/32). 0.0.0.0/0 is not recommended."
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

variable "bastion_version" {
  type        = string
  default     = ""
  description = "Bastion version to use. It can be partial or full value (12, 11.0 , 10.4.3, 10.0.7.28).\n Can be empty for latest pushed image."
}

variable "access_manager_version" {
  type        = string
  default     = ""
  description = "Access Manager version to use. It can be partial or full value (5, 4.0 , 4.4.1, 4.4.1.8).\n Can be empty for latest pushed image."
}

variable "number_of_am" {
  type        = number
  default     = 2
  description = "Number of AM to be deployed"
  validation {
    condition     = contains([0, 1, 2, 3], var.number_of_am)
    error_message = "Value should be between 0 and 3 !"
  }
}

variable "number_of_sm" {
  type        = number
  default     = 2
  description = "Number of SM to be deployed"
  validation {
    condition     = contains([0, 1, 2, 3], var.number_of_sm)
    error_message = "Value should be between 0 and 3 !"
  }
}

variable "install_replication" {
  type        = bool
  default     = false
  description = "Should we install replication on Session Manager ?\n Only valid for bastion 12.0.0 and above.  "
}