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
  default = {}
  description = "Map of tags to apply on instances resources."
  type    = map(string)
}

variable "disk_size" {
  default = 31

}

variable "aws_instance_size" {
  default = "t2.medium"

}

variable "wallix_ami" {

}

variable "disk_type" {

}

variable "key_pair_name" {

}

variable "security_group_id" {

}

variable "user_data" {
  default = ""

}