# AWS Configuration
variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "manual"
}

# Naming and Tags
variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources"
  default     = "payment-poc-manual"
}

variable "company_code" {
  type        = string
  description = "Short company code used in naming"
  default     = "ppay"
}

variable "company_name" {
  type        = string
  description = "Display company name for tags"
  default     = "Payment Provider"
}

variable "owner" {
  type        = string
  description = "Owning team or email"
  default     = "CDE"
}

variable "cost_center" {
  type        = string
  description = "Cost center identifier"
  default     = "PAYDEV"
}

variable "project" {
  type        = string
  description = "Project or application name"
  default     = "payment-poc"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Project     = "pci-dss-compliance"
    Environment = "manual"
    Purpose     = "Import-only fallback for audit"
    ManagedBy   = "Terraform"
  }
}

# Network Configuration
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR (ALB subnet)"
  default     = "10.0.1.0/24"
}

variable "app_subnet_cidr" {
  type        = string
  description = "Application subnet CIDR (private)"
  default     = "10.0.10.0/24"
}

variable "db_subnet_cidr" {
  type        = string
  description = "Database subnet CIDR (private)"
  default     = "10.0.20.0/24"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Security Configuration
variable "authorized_alb_cidrs" {
  type        = list(string)
  description = "Authorized IPs/CIDRs allowed to access ALB"
  default = [
    "203.0.113.10/32"
  ]
}

variable "secureweb_egress_cidr" {
  type        = string
  description = "CIDR block for secureweb.com"
  default     = "198.51.100.0/24"
}

variable "repository_egress_cidr" {
  type        = string
  description = "CIDR block for repository.example.com"
  default     = "203.0.113.0/24"
}

# EC2 Configuration
variable "app_instance_type" {
  type        = string
  description = "EC2 instance type for application server"
  default     = "t3.medium"
}

variable "db_instance_type" {
  type        = string
  description = "EC2 instance type for database server"
  default     = "t3.medium"
}

variable "app_ami_id" {
  type        = string
  description = "AMI ID for application server (Amazon Linux 2)"
  default     = ""
}

variable "db_ami_id" {
  type        = string
  description = "AMI ID for database server (Amazon Linux 2)"
  default     = ""
}

# ASG Configuration
variable "asg_min_size" {
  type        = number
  description = "Minimum number of instances in ASG"
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of instances in ASG"
  default     = 1
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired number of instances in ASG"
  default     = 1
}

# Load Balancer Configuration
variable "alb_internal" {
  type        = bool
  description = "Is ALB internal (false = internet-facing)"
  default     = false
}
