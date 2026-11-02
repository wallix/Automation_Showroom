variable "subscription_id" {
  description = "Azure subscription ID. If null, ARM_SUBSCRIPTION_ID must be set."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the existing Resource Group in which the objects are created. The storage account and the VNet must be in it too."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the existing Virtual Network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing Subnet in which the VM is attached."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the existing Storage Account holding the WALLIX VHD in its vhds container. Must be in the same region as the Resource Group."
  type        = string
}

variable "vm_name" {
  description = "Name of the virtual machine, also used as prefix for the related resources."
  type        = string
}

variable "vm_size" {
  description = "VM size. Run az vm list-sizes to list available options."
  type        = string
  default     = "Standard_B2ms"
}

variable "os_disk_type" {
  description = "Storage type of the managed image and OS disk (Standard_LRS, StandardSSD_LRS, Premium_LRS)."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "am_version" {
  description = "Access Manager version as found in the VHD name: vhds/access-manager-<am_version>-azure.vhd."
  type        = string
  default     = "4.3.0.3"
}

variable "allowed_ips" {
  description = "Public CIDR blocks allowed to reach the VM. Empty (default): no public IP and no NSG are created. Otherwise a static public IP and an NSG opening 80, 443 and 2242 to these CIDRs."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_ips : can(cidrnetmask(cidr))])
    error_message = "allowed_ips must contain valid IPv4 CIDR blocks, e.g. [\"203.0.113.10/32\"]."
  }
}

variable "wabadmin_password" {
  description = "Password of the wabadmin account (also the Azure admin account)."
  type        = string
  sensitive   = true
}

variable "wabsuper_password" {
  description = "Password of the wabsuper account."
  type        = string
  sensitive   = true
}

variable "wabupgrade_password" {
  description = "Password of the wabupgrade account."
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "SSH public key (OpenSSH format) authorized for wabadmin, e.g. file(\"~/.ssh/id_ed25519.pub\") content."
  type        = string
}
