variable "resource_group_name" {
  description = "Specifies the name of the Resource Group in which the objects should exist"
  type        = string
}

variable "virtual_network_name" {
  description = "Specifies the name of an existing Virtual Network in which the objects should exist"
  type        = string
}

variable "subnet_name" {
  description = "Specifies the name of an existing Subnet in which the objects should exist"
  type        = string
}

variable "storage_account_name" {
  description = "Specifies the name of an existing Storage Account name where are stored the vhd"
  type        = string
}

variable "vm_name" {
  description = "Specifies the name of an existing Virtual Network in which the objects should exist"
  type        = string
}

variable "vm_size" {
  description = "Specifies the VM Sizing - use az vm list-sizes to list available options"
  type        = string
  default     = "Standard_B2ms"
}

variable "am_version" {
  description = "Specifies the version of the access manager based on vhd naming"
  type        = string
  default     = "4.3.0.3"
}

variable "wabadmin_password" {
  type      = string
  sensitive = true
}

variable "wabsuper_password" {
  type      = string
  sensitive = true
}

variable "wabupgrade_password" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  description = "Rather than providing the ssh key block, it is possible to source it using file function or script"
  type        = string
  sensitive   = true
}