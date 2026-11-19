# AWS Configuration
variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, production)"
  default     = "dev"
}

# Naming and Tags
variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "payment"
}

variable "naming_prefix" {
  type        = string
  description = "Naming prefix for all resources"
  default     = "payment-poc"
}

variable "company_code" {
  type        = string
  description = "Short company code used in naming (required by common module)"
  default     = "ppay"
}

variable "company_name" {
  type        = string
  description = "Display company name for tags (required by common module)"
  default     = "Payment Provider"
}

variable "owner" {
  type        = string
  description = "Owning team or email (required by common module)"
  default     = "CDE"
}

variable "cost_center" {
  type        = string
  description = "Cost center identifier (required by common module)"
  default     = "PAYDEV"
}

variable "project" {
  type        = string
  description = "Project or application name (required by common module)"
  default     = "payment-poc"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Project     = "pci-dss-compliance"
    Environment = "dev"
    Purpose     = "PCI-DSS 1.3.1 & 1.3.2 Compliance"
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

# Security Configuration - PCI-DSS 1.3.2 (Access Control)
variable "authorized_alb_cidrs" {
  type        = list(string)
  description = "List of authorized IPs/CIDRs allowed to access ALB (finite list for PCI-DSS)"
  default     = []
  validation {
    condition     = length(var.authorized_alb_cidrs) > 0 && !contains(var.authorized_alb_cidrs, "0.0.0.0/0")
    error_message = "authorized_alb_cidrs must contain at least one finite source and cannot include 0.0.0.0/0."
  }
}

variable "secureweb_egress_cidr" {
  type        = string
  description = "CIDR block for secureweb.com (app needs to reach this)"
  default     = ""
  validation {
    condition     = var.secureweb_egress_cidr != "" && var.secureweb_egress_cidr != "0.0.0.0/0"
    error_message = "secureweb_egress_cidr must be an approved finite CIDR."
  }
}

variable "repository_egress_cidr" {
  type        = string
  description = "CIDR block for repository.example.com (for package installation)"
  default     = ""
  validation {
    condition     = var.repository_egress_cidr != "" && var.repository_egress_cidr != "0.0.0.0/0"
    error_message = "repository_egress_cidr must be an approved finite CIDR."
  }
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
  default     = "" # Will use latest Amazon Linux 2 if empty
}

variable "db_ami_id" {
  type        = string
  description = "AMI ID for database server (Amazon Linux 2)"
  default     = "" # Will use latest Amazon Linux 2 if empty
}

# Auto Scaling Configuration
variable "asg_min_size" {
  type        = number
  description = "Minimum number of instances in ASG (1 for POC)"
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of instances in ASG (1 for POC)"
  default     = 1
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired number of instances in ASG (1 for POC)"
  default     = 1
}

# Load Balancer Configuration
variable "ssl_certificate_arn" {
  type        = string
  description = "ARN of existing SSL certificate for ALB"
  default     = "" # Optional: Provide when certificate is ready
  validation {
    condition     = var.ssl_certificate_arn != ""
    error_message = "ssl_certificate_arn must be set to an ACM certificate ARN."
  }
}

variable "alb_internal" {
  type        = bool
  description = "Is ALB internal (false = internet-facing)"
  default     = false
}

# User Data Script for Application Server
variable "app_user_data" {
  type        = string
  description = "User data script for application server"
  default     = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Payment App Server - Dev Environment</h1>" > /var/www/html/index.html
              EOF
}

# User Data Script for Database Server
variable "db_user_data" {
  type        = string
  description = "User data script for database server"
  default     = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mysql-server
              systemctl start mysqld
              systemctl enable mysqld
              EOF
}

# Import Configuration (for Option A: Import existing manual resources)
variable "import_existing_resources" {
  type        = bool
  description = "Whether to import existing manual resources (set to true if resources exist)"
  default     = false
}

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID (if importing manual resources)"
  default     = ""
}

variable "existing_public_subnet_id" {
  type        = string
  description = "Existing public subnet ID (if importing manual resources)"
  default     = ""
}

variable "existing_app_subnet_id" {
  type        = string
  description = "Existing app subnet ID (if importing manual resources)"
  default     = ""
}

variable "existing_db_subnet_id" {
  type        = string
  description = "Existing database subnet ID (if importing manual resources)"
  default     = ""
}

variable "existing_alb_sg_id" {
  type        = string
  description = "Existing ALB security group ID (if importing manual resources)"
  default     = ""
}

variable "existing_app_sg_id" {
  type        = string
  description = "Existing app security group ID (if importing manual resources)"
  default     = ""
}

variable "existing_db_sg_id" {
  type        = string
  description = "Existing database security group ID (if importing manual resources)"
  default     = ""
}

variable "existing_app_instance_id" {
  type        = string
  description = "Existing app EC2 instance ID (if importing manual resources)"
  default     = ""
}

variable "existing_db_instance_id" {
  type        = string
  description = "Existing database EC2 instance ID (if importing manual resources)"
  default     = ""
}

variable "existing_alb_arn" {
  type        = string
  description = "Existing ALB ARN (if importing manual resources)"
  default     = ""
}


