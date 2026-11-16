variable "naming_prefix" {
  type        = string
  description = "Common naming prefix from modules/common."

  validation {
    condition     = length(trimspace(var.naming_prefix)) > 0
    error_message = "naming_prefix cannot be empty."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags from modules/common."

  validation {
    condition     = length(keys(var.tags)) > 0
    error_message = "tags cannot be empty. Pass module.common.tags."
  }
}

variable "security_profile" {
  type = object({
    mode               = string
    enforce_encryption = bool
    enable_logging     = bool
    enforce_tls        = bool
    encryption_key_arn = string
  })
  description = "Common security profile from modules/common."
  default     = null
}

variable "operations_profile" {
  type = object({
    backup_retention_days      = number
    log_retention_days         = number
    enable_monitoring          = bool
    enable_detailed_monitoring = bool
  })
  description = "Common operations profile from modules/common."
  default     = null
}

variable "network_defaults" {
  type = object({
    high_availability = bool
    availability_zones = list(string)
    enable_nat_gateway = bool
  })
  description = "Common network defaults from modules/common."
  default     = null
}

variable "resource_name" {
  type        = string
  description = "Resource name segment."
  default     = "main"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones used for subnet creation."

  validation {
    condition     = length(var.azs) > 0
    error_message = "azs must include at least one availability zone."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks."
  default     = []
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR blocks."
  default     = []
}

variable "enable_internet_gateway" {
  type        = bool
  description = "Enable internet gateway."
  default     = true
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT gateway for private subnets."
  default     = null
}

variable "single_nat_gateway" {
  type        = bool
  description = "Create one NAT gateway for all private subnets."
  default     = true
}

