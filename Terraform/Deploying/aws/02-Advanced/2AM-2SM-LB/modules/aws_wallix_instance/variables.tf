variable "subnet_id" {
  description = "ID of the subnet to use for this instance"
  type        = string
}

variable "project_name" {
  description = "Name of the project. Will be used for Naming and Tags."
  type        = string
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "common_tags" {
  default     = {}
  description = "Map of tags to apply on instances resources."
  type        = map(string)
}

variable "disk_size" {
  default     = 40
  description = "Size of the EBS block for /dev/sda1. Use at least 60 for production"
  type        = number
}

variable "aws_instance_size" {
  default     = "t2.medium"
  description = "Instance size to use. At least t3.xlarge recommended for production."
  type        = string
}

variable "disk_type" {
  default     = "gp3"
  description = "EBS disk type"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the key pair that will be use to connect to the instance."
  type        = string
}

variable "user_data" {
  default     = ""
  description = "Content as cloud-init, plain text rendered or Base64"
  type        = string
}

variable "product_name" {
  description = "Specifies the product to deploy: bastion / access-manager"
  type        = string
  default     = "bastion"
  validation {
    condition     = (var.product_name == "bastion") || (var.product_name == "access-manager") || (var.product_name == "accessmanager")
    error_message = "Value should be bastion or access-manager !"
  }
}
variable "product_version" {
  description = "Specifies the version of the bastion or access-manager.\n It can be empty, partial or full value (5, 4.0 , 4.4.1, 4.4.1.8). Empty value will look for the latest pushed image."
  type        = string
  default     = ""
}

variable "ami_from_aws_marketplace" {
  type        = bool
  default     = true
  description = "Should we use the marketplace image ? If false, the shared image by WALLIX will be use."
}

variable "ami_override" {
  default     = ""
  type        = string
  description = "Force the usage of a specifique AMI-ID"
}
