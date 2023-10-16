variable "access_key" {
  description = "Alibaba Cloud user access key (https://www.alibabacloud.com/help/en/basics-for-beginners/latest/obtain-an-accesskey-pair?spm=a2c63.p38356.0.0.213f4028nVUZ1b#task968)"
}
variable "secret_key" {
  description = "Alibaba Cloud user secret key. This is generated once when the user creates an access key"
}
variable "region" {
  description = "Alibaba Cloud region ID where the resources will be deployed/fetched (https://www.alibabacloud.com/help/en/elastic-compute-service/latest/regions-and-zones)"
}

###############################

variable "resource_group" {
  description = "Alibaba Cloud resources group ID where the resources will be deployed/fetched"
}

variable "vpc" {
  description = "Alibaba Cloud virtual private cloud name"
}
variable "vswitch" {
  description = "Alibaba Cloud virtual switch name"
}

###############################

# Could be PayByBandwidth
variable "internet_charge_type" {
  default = "PayByTraffic"
}

# Allocate public IP (internet_max_bandwidth_out > 0)
variable "internet_max_bandwidth_out" {
  default = 100
}

variable "bastion_cpu" {
  default = 2
}
variable "bastion_memory" {
  default = 8
}
variable "bastion_instance_type" {
  default = "ecs.g7"
}
variable "bastion_private_ip" {
  default = ""
}
variable "bastion_version" {
  default = "10.0.2.9"
}

# mkpasswd --method=SHA-512
variable "wabadmin_password" {}
variable "wabsuper_password" {}
variable "wabupgrade_password" {}

# ssh public key, needed to execute some commands with the root account
variable "ssh_key" {}
# ssh private key file, needed to execute some commands with the root account
variable "private_key_file" {}
