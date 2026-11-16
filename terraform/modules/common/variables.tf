variable "company_code" {
  description = "Short company code used in naming."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, stage, prod."
  type        = string
}

variable "region" {
  description = "AWS region for deployment."
  type        = string
}

variable "owner" {
  description = "Owning team or email."
  type        = string
}

variable "cost_center" {
  description = "Cost center identifier."
  type        = string
}

variable "project" {
  description = "Project or application name."
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework baseline."
  type        = string
  default     = "SOC2"

  validation {
    condition     = contains(["SOC2", "PCI-DSS", "HIPAA", "NONE"], var.compliance_framework)
    error_message = "compliance_framework must be one of: SOC2, PCI-DSS, HIPAA, NONE."
  }
}

variable "mode" {
  description = "Policy mode: strict, balanced, flexible."
  type        = string
  default     = "strict"

  validation {
    condition     = contains(["strict", "balanced", "flexible"], var.mode)
    error_message = "mode must be one of: strict, balanced, flexible."
  }
}

variable "required_tag_keys" {
  description = "Required tag keys enforced by policy."
  type        = list(string)
  default = [
    "Company",
    "Environment",
    "Owner",
    "CostCenter",
    "ManagedBy",
    "Project",
    "CreatedDate",
    "UpdateDate"
  ]
}

variable "company_name" {
  description = "Display company name for tags."
  type        = string
}

variable "managed_by" {
  description = "ManagedBy tag value."
  type        = string
  default     = "Terraform"
}

variable "created_date" {
  description = "CreatedDate tag override. If null, current UTC date is used."
  type        = string
  default     = null
}

variable "update_date" {
  description = "UpdateDate tag override. If null, current UTC date is used."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional organization tags."
  type        = map(string)
  default     = {}
}

variable "resource_naming_pattern" {
  description = "Pattern hint that includes resource type in naming."
  type        = string
  default     = "{company_code}-{environment}-{resource_type}-{name}"
}

variable "enforce_encryption" {
  description = "Whether encryption should be enforced by modules."
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether logging should be enabled by default."
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Whether TLS should be enforced by policy."
  type        = bool
  default     = true
}

variable "encryption_key_arn" {
  description = "Optional KMS key ARN for service-side encryption."
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Default backup retention in days."
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Default log retention in days."
  type        = number
  default     = 90
}

variable "enable_monitoring" {
  description = "Enable monitoring defaults."
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring defaults."
  type        = bool
  default     = false
}

variable "high_availability" {
  description = "Enable high availability defaults."
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Default AZs used by modules that require them."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Default NAT gateway preference."
  type        = bool
  default     = true
}
