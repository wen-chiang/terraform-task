# AWS Configuration
aws_region  = "us-east-1"
environment = "manual"

# Naming and Tagging
naming_prefix = "payment-poc-manual"
company_code  = "ppay"
company_name  = "Payment Provider"
owner         = "CDE"
cost_center   = "PAYDEV"
project       = "payment-poc"

tags = {
  Project     = "pci-dss-compliance"
  Environment = "manual"
  Purpose     = "Import-only fallback for audit"
  ManagedBy   = "Terraform"
}

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
app_subnet_cidr    = "10.0.10.0/24"
db_subnet_cidr     = "10.0.20.0/24"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Security Configuration
authorized_alb_cidrs   = ["203.0.113.10/32"] # Replace with approved source IPs
secureweb_egress_cidr  = "198.51.100.0/24"   # Replace with actual secureweb.com CIDR
repository_egress_cidr = "203.0.113.0/24"    # Replace with actual repository CIDR

# Compute Configuration
app_instance_type    = "t3.medium"
db_instance_type     = "t3.medium"
app_ami_id           = ""
db_ami_id            = ""
asg_min_size         = 1
asg_max_size         = 1
asg_desired_capacity = 1

# Load Balancer Configuration
alb_internal = false
