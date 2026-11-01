# General Variables
variable "product_name" {
  description = "WALLIX product to deploy: bastion or access-manager."
  type        = string

  validation {
    condition     = var.product_name == "access-manager" || var.product_name == "bastion"
    error_message = "The product_name must be 'bastion' or 'access-manager'."
  }
}

variable "product_version" {
  description = "Full product version (x.y.z.q), as found in the image archive name <product_name>-<product_version>-gcp.tar.gz."
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.product_version))
    error_message = "The format of 'product_version' must be 'x.y.z.q'."
  }
}

variable "cidr_range" {
  description = "CIDR range of the subnetwork created for the instance."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_range))
    error_message = "cidr_range must be a valid IPv4 CIDR block."
  }
}

variable "allowed_ip" {
  description = "CIDR blocks allowed to reach the instance. Use your own public IP as x.x.x.x/32; 0.0.0.0/0 exposes the instance to the whole Internet."
  type        = list(string)

  validation {
    condition     = length(var.allowed_ip) > 0 && alltrue([for cidr in var.allowed_ip : can(cidrnetmask(cidr))])
    error_message = "allowed_ip must contain at least one valid IPv4 CIDR block, e.g. [\"203.0.113.10/32\"]."
  }
}

## GCP
variable "gcp_project_name" {
  description = "ID of the GCP project to deploy into."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
  default     = "europe-west1"
}

variable "gcp_region_zone" {
  description = "GCP zone, inside gcp_region."
  type        = string
  default     = "europe-west1-b"
}

variable "gcp_instance_size" {
  description = "Machine type of the instance."
  type        = string
  default     = "e2-small"
}

variable "gcp_credentials_file_path" {
  description = "Path to a service account key file. Leave null to use Application Default Credentials (recommended)."
  type        = string
  default     = null
}

variable "gcp_bucket_name" {
  description = "Cloud Storage bucket holding the WALLIX image archive <product_name>-<product_version>-gcp.tar.gz."
  type        = string
}

variable "wabadmin_password" {
  description = "Password of the wabadmin account."
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

variable "ssh_key_root" {
  description = "SSH public key authorized for root, e.g. \"ssh-ed25519 AAAA... user@host\"."
  type        = string
  sensitive   = true
}

variable "ssh_key_wabadmin" {
  description = "SSH public key authorized for wabadmin, e.g. \"ssh-ed25519 AAAA... user@host\"."
  type        = string
  sensitive   = true
}
