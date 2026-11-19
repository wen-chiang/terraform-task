# ============================================================================
# PCI-DSS Development Environment - Terraform Variables
# ============================================================================
# 
# This file contains all the configuration values for the development
# environment. Update these values before deploying.
#
# IMPORTANT: Before deploying, make sure to update:
# 1. ssl_certificate_arn - Get from AWS Certificate Manager
# 2. authorized_alb_cidrs - Add your actual authorized IPs (not 0.0.0.0/0)
# 3. secureweb_egress_cidr - Replace with actual secureweb.com IP range
# 4. repository_egress_cidr - Replace with actual repository.example.com IP range
#
# ============================================================================

# AWS Configuration
aws_region  = "us-east-1"
environment = "dev"

# Naming and Tagging
project_name  = "payment"
naming_prefix = "payment-poc-dev"
company_code  = "ppay"
company_name  = "Payment Provider"
owner         = "CDE"
cost_center   = "PAYDEV"
project       = "payment-poc"

tags = {
  Project     = "pci-dss-compliance"
  Environment = "dev"
  Purpose     = "PCI-DSS 1.3.1 & 1.3.2 Compliance - POC"
  ManagedBy   = "Terraform"
  Team        = "DevOps"
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"  # ALB subnet (public)
app_subnet_cidr    = "10.0.10.0/24" # Application subnet (private)
db_subnet_cidr     = "10.0.20.0/24" # Database subnet (private)
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# ============================================================================
# SECURITY CONFIGURATION - PCI-DSS 1.3.2
# IMPORTANT: Update authorized_alb_cidrs with actual IPs before production
# ============================================================================

authorized_alb_cidrs = [
  # Replace these examples with the approved office, VPN, or remote-office CIDRs.
  "203.0.113.5/32",
  "198.51.100.0/24"
]

# External service connectivity
# These should be replaced with actual IP ranges
secureweb_egress_cidr  = "198.51.100.10/32" # Replace with the resolved secureweb.com range
repository_egress_cidr = "203.0.113.10/32"  # Replace with the resolved repository.example.com range

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================

# Application Server
app_instance_type = "t3.medium" # Instance type for app server
app_ami_id        = ""          # Leave empty for latest Amazon Linux 2

# Database Server
db_instance_type = "t3.medium" # Instance type for database server
db_ami_id        = ""          # Leave empty for latest Amazon Linux 2

# ============================================================================
# AUTO SCALING CONFIGURATION
# For POC: Set min/max/desired = 1 (single instance)
# ============================================================================

asg_min_size         = 1 # Minimum instances
asg_max_size         = 1 # Maximum instances
asg_desired_capacity = 1 # Desired instances (single for POC)

# ============================================================================
# LOAD BALANCER CONFIGURATION
# IMPORTANT: Update ssl_certificate_arn when your AWS certificate is ready
# ============================================================================

# Get certificate ARN from AWS Certificate Manager console:
# AWS Console â†’ Certificate Manager â†’ Copy ARN from your certificate
# Format: arn:aws:acm:us-east-1:123456789012:certificate/abcdef01-2345-6789-abcd-ef0123456789
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/REPLACE-ME" # Replace with a real ACM certificate ARN

alb_internal = false # false = internet-facing, true = internal

# ============================================================================
# USER DATA SCRIPTS
# These scripts run when instances start
# ============================================================================

# Application server user data (installs web server)
app_user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail
              exec > >(tee /var/log/bootstrap.log | logger -t user-data -s 2>/dev/console) 2>&1

              PKG_URL="https://repository.example.com/packages/myapp.rpm"
              PKG_FILE="/tmp/myapp.rpm"

              retry() {
                local n=0
                local max=5
                local delay=10
                until "$@"; do
                  n=$((n+1))
                  if [ "$n" -ge "$max" ]; then
                    echo "Command failed after $n attempts: $*"
                    return 1
                  fi
                  sleep "$delay"
                done
              }

              yum update -y
              retry curl -fL --connect-timeout 10 --max-time 120 "$PKG_URL" -o "$PKG_FILE"
              retry yum localinstall -y "$PKG_FILE"

              # App starts only if package install succeeded
              systemctl daemon-reload
              systemctl enable myapp
              systemctl start myapp
              systemctl is-active --quiet myapp
              EOF

# Database server user data (installs MySQL)
db_user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mysql-server
              systemctl start mysqld
              systemctl enable mysqld
              EOF

# ============================================================================
# IMPORT CONFIGURATION (For Option A: Import existing manual resources)
# Set to true if you have existing manual infrastructure to import
# ============================================================================

import_existing_resources = false

# If import_existing_resources = true, provide existing resource IDs:
# (Get these from AWS Console â†’ EC2 Dashboard â†’ Resources)

existing_vpc_id           = "" # e.g., "vpc-12345678"
existing_public_subnet_id = "" # e.g., "subnet-xxxxxxx"
existing_app_subnet_id    = "" # e.g., "subnet-yyyyyyy"
existing_db_subnet_id     = "" # e.g., "subnet-zzzzzzz"
existing_alb_sg_id        = "" # e.g., "sg-alb-123456"
existing_app_sg_id        = "" # e.g., "sg-app-123456"
existing_db_sg_id         = "" # e.g., "sg-db-123456"
existing_app_instance_id  = "" # e.g., "i-app-123456789"
existing_db_instance_id   = "" # e.g., "i-db-123456789"
existing_alb_arn          = "" # e.g., "arn:aws:elasticloadbalancing:..."

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================
#
# 1. BEFORE DEPLOYING:
#    - Update ssl_certificate_arn (REQUIRED)
#    - Update authorized_alb_cidrs with actual IPs (IMPORTANT for security)
#    - Update secureweb_egress_cidr with actual IP range
#    - Update repository_egress_cidr with actual IP range
#
# 2. VALIDATE:
#    terraform plan
#
# 3. DEPLOY:
#    terraform apply
#
# 4. VERIFY:
#    - Check AWS Console for created resources
#    - Test ALB connectivity (use DNS name from terraform output)
#    - Verify security group rules
#
# 5. CLEANUP (when done):
#    terraform destroy
#
# ============================================================================

