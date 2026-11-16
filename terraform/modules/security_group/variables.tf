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

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "resource_name" {
  type        = string
  description = "Resource name segment."
  default     = "baseline"
}

variable "app_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = string
    description = string
  }))
  default = []
}

variable "app_egress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = string
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]
}

variable "db_port" {
  type        = number
  description = "Database listener port."
  default     = 5432
}

