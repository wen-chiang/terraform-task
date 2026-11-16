# PCI-DSS Development Environment - Terraform Configuration

## Overview

This Terraform configuration deploys a **PCI-DSS compliant infrastructure** in the **development environment** on AWS. It addresses PCI-DSS requirements **1.3.1** (network segmentation) and **1.3.2** (access control) through a 3-tier architecture.

## Architecture

### Network Segmentation (PCI-DSS 1.3.1)

```
Internet (0.0.0.0/0)
    ↓ HTTPS:443 (restricted IPs)
┌─────────────────────┐
│   ALB (Public)      │  ← Tier 1: Internet-facing load balancer
│   10.0.1.0/24       │
└──────────┬──────────┘
           ↓ Port 8080 (ALB→App only)
┌──────────────────────┐
│   App Server (Private)│ ← Tier 2: Application servers
│   10.0.10.0/24       │
└──────────┬───────────┘
           ↓ Port 3306 (App→DB only)
┌──────────────────────┐
│  Database (Private)   │ ← Tier 3: Database servers
│   10.0.20.0/24       │
└──────────────────────┘
```

### Access Control (PCI-DSS 1.3.2)

**Inbound Rules:**
- ALB: Accept HTTPS:443 from authorized IPs only (finite list)
- App: Accept port 8080 from ALB security group only
- Database: Accept port 3306 from App security group only

**Outbound Rules:**
- App: Allow to secureweb.com and repository.example.com (restricted)
- Database: Deny all outbound (isolated)

## Project Structure

```
environments/dev/
├── main.tf                  # Module orchestration
├── variables.tf             # Variable definitions
├── outputs.tf               # Output values
├── terraform.tfvars         # Configuration values
├── versions.tf              # Provider & Terraform versions
└── README.md                # This file
```

## Prerequisites

### AWS Account Setup

1. **AWS Account** with appropriate permissions
2. **AWS Credentials** configured locally:
   ```bash
   aws configure
   ```

3. **SSL Certificate** (from AWS Certificate Manager)
   - Create or import an SSL certificate in ACM
   - Note the certificate ARN (required for deployment)

### Local Setup

1. **Terraform** (>= 1.0)
   ```bash
   terraform version
   ```

2. **AWS CLI** (optional, for verification)
   ```bash
   aws --version
   ```

## Configuration

### Step 1: Update terraform.tfvars

Before deploying, update `terraform.tfvars` with your values:

**REQUIRED - Must be updated:**

```hcl
# Your AWS region
aws_region = "us-east-1"

# SSL Certificate ARN (from AWS Certificate Manager)
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/abcd-1234-..."

# Authorized IPs for ALB access (replace 0.0.0.0/0 with actual IPs!)
authorized_alb_cidrs = [
  "203.0.113.5/32",          # Your office IP
  "198.51.100.0/24",         # VPN subnet
]
```

**RECOMMENDED - Should be updated:**

```hcl
# Replace with actual IP ranges
secureweb_egress_cidr = "198.51.100.0/24"       # secureweb.com IP range
repository_egress_cidr = "203.0.113.0/24"       # repository.example.com IP range
```

**OPTIONAL - Use defaults for POC:**

```hcl
app_instance_type = "t3.medium"
db_instance_type = "t3.medium"
asg_min_size = 1
asg_max_size = 1
asg_desired_capacity = 1
```

### Step 2: Validate Configuration

```bash
# Initialize Terraform
terraform init

# Validate syntax
terraform validate

# Review what will be created
terraform plan
```

### Step 3: Deploy Infrastructure

```bash
# Deploy to AWS
terraform apply

# Review changes and confirm with 'yes'
```

## Deployment

### Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

**Output:**
```
Terraform has been successfully configured!
```

### Plan Deployment

```bash
terraform plan -out=tfplan
```

**Output:** Shows all resources that will be created

### Apply Configuration

```bash
terraform apply tfplan
```

**Output:** Infrastructure deployed to AWS

### Verify Deployment

```bash
# Get outputs
terraform output

# Example output:
# alb_dns_name = "payment-poc-dev-alb-1234567890.us-east-1.elb.amazonaws.com"
# vpc_id = "vpc-abc123def456"
# app_subnet_id = "subnet-xxxxxxx"
```

## Outputs

After successful deployment, you'll get:

```
vpc_id                      - VPC ID
vpc_cidr                    - VPC CIDR block

public_subnet_id            - ALB subnet ID
app_subnet_id               - Application subnet ID (private)
database_subnet_id          - Database subnet ID (private)

alb_dns_name                - Load balancer DNS name
alb_arn                     - Load balancer ARN
alb_zone_id                 - Load balancer zone ID

app_asg_id                  - Application ASG ID
db_asg_id                   - Database ASG ID

pci_compliance_summary      - PCI-DSS compliance details
application_url             - Full URL to application

environment                 - Environment name (dev)
region                      - AWS region
naming_prefix               - Naming prefix used
```

## Accessing the Application

After deployment:

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Access application (via ALB)
https://$ALB_DNS
```

## Security Group Rules

### ALB Security Group

| Direction | Protocol | Port | Source | Purpose |
|-----------|----------|------|--------|---------|
| Inbound | HTTPS | 443 | Authorized IPs | PCI-DSS 1.3.2 |
| Inbound | HTTP | 80 | ALB subnet | Internal redirect |
| Outbound | All | All | 0.0.0.0/0 | ALB to app tier |

### Application Security Group

| Direction | Protocol | Port | Source/Destination | Purpose |
|-----------|----------|------|-------------------|---------|
| Inbound | TCP | 8080 | ALB SG | ALB to app traffic |
| Outbound | HTTPS | 443 | secureweb.com | External service access |
| Outbound | HTTPS | 443 | repository.example.com | Package installation |

### Database Security Group

| Direction | Protocol | Port | Source | Purpose |
|-----------|----------|------|--------|---------|
| Inbound | TCP | 3306 | App SG | App to database |
| Outbound | All | All | (blocked) | No outbound traffic |

## Troubleshooting

### Issue: SSL Certificate not found

**Error:** `Error: certificate not found in region`

**Solution:**
1. Go to AWS Certificate Manager console
2. Copy the certificate ARN
3. Update `ssl_certificate_arn` in `terraform.tfvars`

### Issue: Insufficient permissions

**Error:** `Error: creating security group: ...unauthorized operation`

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Configure new credentials
aws configure
```

### Issue: Instance not starting

**Error:** Launch template error or instance fails to launch

**Solution:**
1. Check instance type availability in region
2. Verify AMI ID exists in region
3. Check security group rules allow necessary ports

### Issue: Cannot access ALB

**Error:** Connection timeout or refused

**Solution:**
1. Verify ALB DNS name: `terraform output alb_dns_name`
2. Check security group allows your IP
3. Wait 2-3 minutes for ALB to be fully ready

## Import Workflow (Option A: Existing Manual Resources)

If you have existing manual infrastructure to import:

### Step 1: Set import_existing_resources = true

In `terraform.tfvars`:
```hcl
import_existing_resources = true

existing_vpc_id = "vpc-12345678"
existing_public_subnet_id = "subnet-xxxxxxx"
# ... provide all existing resource IDs
```

### Step 2: Create resource definitions in main.tf

Add empty resource definitions for each existing resource.

### Step 3: Run terraform import

```bash
# Import each resource
terraform import aws_vpc.main vpc-12345678
terraform import aws_subnet.public subnet-xxxxxxx
# ... import all resources
```

### Step 4: Verify sync

```bash
terraform plan
# Should show "No changes. Infrastructure is up-to-date."
```

## Cleanup

To destroy all resources and avoid charges:

```bash
# Review what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy

# Confirm with 'yes'
```

## Best Practices

✅ **DO:**
- Always run `terraform plan` before `apply`
- Keep `terraform.tfvars` up-to-date
- Use restricted IP lists (not 0.0.0.0/0)
- Review security group rules regularly
- Keep Terraform state file backed up

❌ **DON'T:**
- Manually modify resources in AWS Console
- Commit `terraform.tfvars` with real IPs to git
- Leave `authorized_alb_cidrs = ["0.0.0.0/0"]` in production
- Delete Terraform state file without backup

## PCI-DSS Compliance Checklist

- [ ] Network segmentation implemented (3 tiers)
- [ ] ALB exposed only to authorized IPs
- [ ] App tier isolated from internet
- [ ] Database tier isolated from internet
- [ ] Security group rules restrict inbound/outbound
- [ ] Outbound traffic limited to known destinations
- [ ] All resources tagged with environment/project
- [ ] Infrastructure repeatably deployed via Terraform

## Support & Documentation

For more information:

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Groups Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security.html)
- [PCI-DSS Requirement 1.3](https://www.pcisecuritystandards.org/)

## Module References

Each module in `../../modules/` has its own README.md:

- `modules/common/README.md` - Naming and tagging
- `modules/vpc/README.md` - VPC and networking
- `modules/security_group/README.md` - Security groups
- `modules/alb_nlb/README.md` - Load balancer
- `modules/ec2_asg/README.md` - EC2 and auto scaling

## Environment Progression

This dev environment is the first step. The same configuration can be promoted to:

1. **Dev** ← You are here (POC)
2. **Staging** (pre-production testing)
3. **Production** (live environment)

Each environment uses separate `environments/[env]/` folders with their own `terraform.tfvars`.

---

**Last Updated:** 2024
**Environment:** Development
**PCI-DSS Compliance:** 1.3.1 & 1.3.2
