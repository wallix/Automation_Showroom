//TODO: document the variables
variable "subnet_id" {
  description = "ID of the subnet to use for this instance"
  type        = string
}

variable "project_name" {
  type        = string
  description = "value"
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
  default = 31

}

variable "aws_instance_size" {
  default = "t2.medium"

}

variable "disk_type" {

}

variable "key_pair_name" {

}

variable "user_data" {
  default = ""

}

variable "product_name" {
  description = "Specifies the product to deploy: bastion / access-manager"
  type        = string
  default     = "bastion"
  validation {
    condition     = (var.product_name == "bastion") || (var.product_name == "access-manager")
    error_message = "Value should be bastion or access-manager !"
  }
}
variable "product_version" {
  description = "Specifies the version of the bastion or access-manager. It can be empty, partial or full value (5, 4.0 , 4.4.1, 4.4.1.8). Empty value will look for the latest pushed image."
  type        = string
  default     = ""
}

variable "ami-from-aws-marketplace" {
  type        = bool
  default     = true
  description = "Should we use the marketplace image ? If false, the shared image by WALLIX will be use."
}