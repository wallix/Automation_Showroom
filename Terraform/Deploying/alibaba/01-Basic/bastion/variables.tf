variable "access_key" {
  description = "Alibaba Cloud AccessKey ID. If null, the provider reads ALICLOUD_ACCESS_KEY (or ALICLOUD_PROFILE)."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "Alibaba Cloud AccessKey secret. If null, the provider reads ALICLOUD_SECRET_KEY (or ALICLOUD_PROFILE)."
  type        = string
  default     = null
  sensitive   = true
}

variable "region" {
  description = "Alibaba Cloud region ID, e.g. eu-central-1."
  type        = string
}

###############################

variable "resource_group" {
  description = "ID of the existing resource group in which the instance is created."
  type        = string
}

variable "vpc" {
  description = "Name of the existing VPC. The instance uses the first security group found in it."
  type        = string
}

variable "vswitch" {
  description = "Name of the existing vSwitch (subnet) to attach the instance to."
  type        = string
}

###############################

variable "internet_charge_type" {
  description = "Public bandwidth billing: PayByTraffic or PayByBandwidth."
  type        = string
  default     = "PayByTraffic"
}

variable "internet_max_bandwidth_out" {
  description = "Outbound public bandwidth in Mbit/s. A value above 0 allocates a public IP, which the provisioning step needs."
  type        = number
  default     = 100
}

variable "bastion_cpu" {
  description = "vCPU count used to select the instance type."
  type        = number
  default     = 2
}

variable "bastion_memory" {
  description = "Memory (GiB) used to select the instance type."
  type        = number
  default     = 8
}

variable "bastion_instance_type" {
  description = "Instance type family used to select the instance type."
  type        = string
  default     = "ecs.g7"
}

variable "bastion_private_ip" {
  description = "Fixed private IP inside the vSwitch. Null lets Alibaba Cloud pick one."
  type        = string
  default     = null
}

variable "bastion_version" {
  description = "Bastion version; the custom image name must start with bastion-<version>."
  type        = string
  default     = "10.0.2.9"
}

# Hashes, not cleartext: mkpasswd --method=SHA-512
variable "wabadmin_password" {
  description = "SHA-512 crypt hash of the wabadmin password."
  type        = string
  sensitive   = true
}

variable "wabsuper_password" {
  description = "SHA-512 crypt hash of the wabsuper password."
  type        = string
  sensitive   = true
}

variable "wabupgrade_password" {
  description = "SHA-512 crypt hash of the wabupgrade password."
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "SSH public key authorized for wabadmin and root."
  type        = string
}

variable "private_key_file" {
  description = "Path to the private key matching ssh_key, used by Terraform to run the post-install commands as root on port 2242."
  type        = string
}
