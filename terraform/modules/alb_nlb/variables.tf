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

variable "module_settings" {
  type = object({
    internal = optional(any)
    load_balancer_type = optional(any)
    name = optional(any)
    security_group_ids = optional(any)
    subnet_ids = optional(any)
    tags = optional(any)
    target_groups = optional(any)
    vpc_id = optional(any)
  })
  description = "Module-specific settings."
  default     = {}
}



