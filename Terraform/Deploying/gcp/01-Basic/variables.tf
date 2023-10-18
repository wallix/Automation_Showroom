# General Variables
variable "product_name" {
  description = "WALLIX product"
  validation {
    condition     = var.product_name == "access-manager" || var.product_name == "bastion"
    error_message = "The product_name must be 'bastion' or 'access-manager'."
  }
}

variable "product_version" {
  description = "Version of WALLIX Product"
  validation {
    condition     = length(try(regex("\\d+\\.\\d+\\.\\d+\\.\\d+", var.product_version), "")) > 0
    error_message = "The format of 'product_version' must be in for 'x.y.z.q'."
  }
}
variable "cidr_range" {
  type        = string
  description = "CIDR Range on targeted network"
  # default     = "10.0.0.0/16"

}


variable "allowed_ip" {
  type = list(string)
  # default     = ["0.0.0.0/0"]
  description = "Allow these IP address to connect VMs"
}

## GCP
variable "gcp_project_name" {
  type    = string
  default = "testwab-143414"
}
variable "gcp_region" {
  type    = string
  default = "europe-west1"
}
variable "gcp_region_zone" {
  type    = string
  default = "europe-west1-b"
}

variable "gcp_instance_size" {
  type    = string
  default = "e2-small"
}

variable "gcp_credentials_file_path" {
  type    = string
  default = "gcp_key.json"
}

variable "gcp_bucket_name" {
  type    = string
  default = "bastion-gcp"
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

variable "ssh_key_root" {
  type        = string
  description = "ssh-rsa mypublickey user1@host.com"
  sensitive   = true
}

variable "ssh_key_wabadmin" {
  description = "ssh-rsa mypublickey user2@host.com"
  type        = string
  sensitive   = true
}