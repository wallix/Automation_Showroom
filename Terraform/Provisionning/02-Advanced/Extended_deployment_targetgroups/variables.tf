# Variables for WALLIX Bastion Extended Deployment

variable "bastion_ip" {
  description = "IP address of the WALLIX Bastion"
  type        = string
}

variable "bastion_user" {
  description = "Username for WALLIX Bastion API authentication"
  type        = string
  default     = "admin"
}

variable "bastion_password" {
  description = "Password for WALLIX Bastion API authentication"
  type        = string
  sensitive   = true
}

variable "bastion_port" {
  description = "Port for WALLIX Bastion API"
  type        = number
  default     = 443
}

variable "inventory_format" {
  description = "Format of inventory files (yaml or json)"
  type        = string
  default     = "yaml"
  validation {
    condition     = contains(["yaml", "json"], var.inventory_format)
    error_message = "Inventory format must be either 'yaml' or 'json'."
  }
}

variable "create_default_timeframes" {
  description = "Create default timeframes for authorizations"
  type        = bool
  default     = true
}

variable "default_user_profile" {
  description = "Default profile for users"
  type        = string
  default     = "user"
  validation {
    condition     = contains(["user", "admin", "auditor"], var.default_user_profile)
    error_message = "User profile must be one of: user, admin, auditor."
  }
}

variable "enable_password_policies" {
  description = "Enable password policies for accounts"
  type        = bool
  default     = true
}

variable "default_connection_policy" {
  description = "Default connection policy for devices"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "wallix-extended-deployment"
  }
}