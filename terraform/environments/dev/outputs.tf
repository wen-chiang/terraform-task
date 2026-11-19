# VPC Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "VPC CIDR block"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = module.vpc.public_subnet_ids[0]
  description = "Public subnet ID (ALB)"
}

output "app_subnet_id" {
  value       = module.vpc.private_subnet_ids[0]
  description = "Application subnet ID (private)"
}

output "database_subnet_id" {
  value       = module.vpc.private_subnet_ids[1]
  description = "Database subnet ID (private)"
}

# Security Group Outputs
output "alb_security_group_id" {
  value       = module.security_groups.alb_sg_id
  description = "ALB security group ID"
}

output "app_security_group_id" {
  value       = module.security_groups.app_sg_id
  description = "Application security group ID"
}

output "database_security_group_id" {
  value       = module.security_groups.db_sg_id
  description = "Database security group ID"
}

# Load Balancer Outputs
output "alb_dns_name" {
  value       = module.load_balancer.lb_dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = module.load_balancer.lb_arn
  description = "Module name of the Application Load Balancer"
}

output "alb_zone_id" {
  value       = module.load_balancer.lb_zone_id
  description = "Module name of the Application Load Balancer"
}

# Application Server Outputs
output "app_asg_id" {
  value       = try(module.app_server.asg_name, "N/A")
  description = "Application Auto Scaling Group name"
}

output "app_asg_name" {
  value       = module.app_server.asg_name
  description = "Application Auto Scaling Group name"
}

# Database Server Outputs
output "db_asg_id" {
  value       = try(module.database_server.asg_name, "N/A")
  description = "Database Auto Scaling Group name"
}

output "db_asg_name" {
  value       = module.database_server.asg_name
  description = "Database Auto Scaling Group name"
}

# PCI-DSS Compliance Outputs
output "pci_compliance_summary" {
  value = {
    requirement_1_3_1 = "Network segmentation: 3-tier architecture (ALB → App → DB)"
    requirement_1_3_2 = "Access control: Restricted inbound/outbound rules configured"
    network_tiers = {
      public      = module.vpc.public_subnet_ids[0]
      application = module.vpc.private_subnet_ids[0]
      database    = module.vpc.private_subnet_ids[1]
    }
    access_control = {
      alb_allowed_sources = var.authorized_alb_cidrs
      secureweb_egress    = var.secureweb_egress_cidr
      repository_egress   = var.repository_egress_cidr
      app_to_db_port      = "3306"
      alb_to_app_port     = "8080"
    }
  }
  description = "PCI-DSS 1.3.1 & 1.3.2 compliance configuration summary"
}

# Infrastructure URL for Access
output "application_url" {
  value       = "https://${module.load_balancer.lb_dns_name}"
  description = "Application URL through ALB"
}

# Environment Info
output "environment" {
  value       = var.environment
  description = "Environment name"
}

output "region" {
  value       = var.aws_region
  description = "AWS region"
}

output "naming_prefix" {
  value       = var.naming_prefix
  description = "Naming prefix used for resources"
}
