# Terraform Import Guide - Importing Existing Resources to tfstate

**Purpose**: Document how to import existing manual infrastructure into Terraform state file  
**Use Case**: When you have existing resources running in AWS that you want Terraform to manage  
**Timeline**: After infrastructure is manually built, before making changes via Terraform

---

## Why Import Existing Resources?

Current State:
- AWS Account: Has manual infrastructure (VPC, EC2, ALB, etc.)
- Terraform State: Empty (no resources tracked)
- Problem: No IaC control, manual changes risky, hard to replicate

After Import:
- AWS Account: Same infrastructure
- Terraform State: Tracks all resources
- Benefit: Full IaC control, repeatable, audit-ready

---

## Pre-Import Checklist

Before importing, you MUST have:

- [ ] All resource IDs documented - VPC ID, Subnet IDs, Security Group IDs, Instance IDs, etc.
- [ ] terraform.tfvars populated - All variables match your existing infrastructure
- [ ] main.tf configured - Terraform code matches how resources are deployed
- [ ] Terraform initialized - Run 	erraform init in your environment directory
- [ ] AWS credentials configured - Run ws configure with appropriate permissions

---

## Information to Gather FIRST

### From AWS Console - Collect These IDs

**VPC Information:**
- VPC ID: vpc-xxxxxxxx
- VPC CIDR: 10.0.0.0/16
- Availability Zones: us-east-1a, us-east-1b, us-east-1c

**Subnet Information:**
- Public Subnet (ALB):
  - Subnet ID: subnet-public
  - CIDR: 10.0.1.0/24
  - AZ: us-east-1a
- App Subnet (Private):
  - Subnet ID: subnet-app
  - CIDR: 10.0.10.0/24
  - AZ: us-east-1b
- Database Subnet (Private):
  - Subnet ID: subnet-db
  - CIDR: 10.0.20.0/24
  - AZ: us-east-1c

**Security Group Information:**
- ALB Security Group ID: sg-alb
- App Security Group ID: sg-app
- Database Security Group ID: sg-db

**Load Balancer Information:**
- ALB Name: payment-poc-alb
- Target Group Name: payment-poc-tg
- Target Group ARN: arn:aws:elasticloadbalancing:...

**EC2 Instance Information:**
- App Instance ID: i-app
- Database Instance ID: i-db
- Auto Scaling Group Names:
  - App ASG: payment-poc-app-asg
  - Database ASG: payment-poc-db-asg

**Certificate Information:**
- SSL Certificate ARN: arn:aws:acm:us-east-1:...

---

## Step 1: Update terraform.tfvars with Existing Values

**Location**: terraform/environments/dev/terraform.tfvars

Update these values to match your AWS infrastructure:

`
# Network Configuration - Use EXISTING values from AWS
vpc_cidr           = "10.0.0.0/16"          # Must match AWS VPC CIDR
public_subnet_cidr = "10.0.1.0/24"          # Must match AWS subnet CIDR
app_subnet_cidr    = "10.0.10.0/24"         # Must match AWS subnet CIDR
db_subnet_cidr     = "10.0.20.0/24"         # Must match AWS subnet CIDR

# Security Configuration
authorized_alb_cidrs = ["203.0.113.0/32"]   # Your actual authorized IPs

# Load Balancer
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234..."

# Instance Types - Must match what's running
app_instance_type = "t3.medium"             # Must match AWS instance type
db_instance_type  = "t3.medium"             # Must match AWS instance type

# ASG Configuration - Must match existing settings
asg_min_size         = 1
asg_max_size         = 1
asg_desired_capacity = 1
`

---

## Step 2: Verify terraform.tfvars Matches AWS Reality

Run this command:

`
terraform validate
`

If validation passes, your configuration matches expectations!

---

## Step 3: Import Resources One by One

**IMPORTANT**: Import in this order (dependencies first)

### 3a. Import VPC

`
terraform import module.vpc.aws_vpc.this vpc-xxxxxxxx
`

Example:
`
terraform import module.vpc.aws_vpc.this vpc-12345678
`

Verify:
`
terraform state show module.vpc.aws_vpc.this
`

---

### 3b. Import Subnets

`
# Public Subnet (ALB)
terraform import 'module.vpc.aws_subnet.this[0]' subnet-public-id

# App Private Subnet
terraform import 'module.vpc.aws_subnet.this[1]' subnet-app-id

# Database Private Subnet
terraform import 'module.vpc.aws_subnet.this[2]' subnet-db-id
`

Example:
`
terraform import 'module.vpc.aws_subnet.this[0]' subnet-aaaaaaaa
terraform import 'module.vpc.aws_subnet.this[1]' subnet-bbbbbbbb
terraform import 'module.vpc.aws_subnet.this[2]' subnet-cccccccc
`

Verify:
`
terraform state list | grep subnet
`

---

### 3c. Import Security Groups

`
# ALB Security Group
terraform import module.security_groups.aws_security_group.app sg-alb-id

# App Security Group  
terraform import module.security_groups.aws_security_group.app sg-app-id

# Database Security Group
terraform import module.security_groups.aws_security_group.db sg-db-id
`

Example:
`
terraform import module.security_groups.aws_security_group.app sg-11111111
terraform import module.security_groups.aws_security_group.app sg-22222222
terraform import module.security_groups.aws_security_group.db sg-33333333
`

Verify:
`
terraform state list | grep security_group
`

---

### 3d. Import Load Balancer

`
# ALB Load Balancer
terraform import module.load_balancer.aws_lb.this arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/payment-poc-alb/abcd1234

# Target Group
terraform import 'module.load_balancer.aws_lb_target_group.this[0]' arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/payment-poc-tg/abcd1234
`

Example:
`
terraform import module.load_balancer.aws_lb.this \
  arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/payment-poc-alb/abc123def456

terraform import 'module.load_balancer.aws_lb_target_group.this[0]' \
  arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/payment-poc-tg/abc123def456
`

Verify:
`
terraform state list | grep load_balancer
`

---

### 3e. Import Auto Scaling Groups

`
# Application Auto Scaling Group
terraform import module.app_server.aws_autoscaling_group.this payment-poc-app-asg

# Database Auto Scaling Group
terraform import module.database_server.aws_autoscaling_group.this payment-poc-db-asg
`

Example:
`
terraform import module.app_server.aws_autoscaling_group.this payment-poc-app-asg
terraform import module.database_server.aws_autoscaling_group.this payment-poc-db-asg
`

Verify:
`
terraform state list | grep autoscaling
`

---

## Step 4: Verify All Imports Succeeded

`
# Check all imported resources
terraform state list

# Should show:
# - module.vpc.aws_vpc.this
# - module.vpc.aws_subnet.this[0]
# - module.vpc.aws_subnet.this[1]
# - module.vpc.aws_subnet.this[2]
# - module.security_groups.aws_security_group.app
# - module.security_groups.aws_security_group.db
# - module.load_balancer.aws_lb.this
# - module.load_balancer.aws_lb_target_group.this[0]
# - module.app_server.aws_autoscaling_group.this
# - module.database_server.aws_autoscaling_group.this

# Count total resources
terraform state list | wc -l
`

---

## Step 5: Run terraform plan - CRITICAL STEP

`
terraform plan
`

**Expected Result**: No changes. Infrastructure is up-to-date.

**Why This Is Critical**:
- If plan shows "0 changes" → Everything is perfect! ✅
- If plan shows changes → Something doesn't match between code and reality ❌

---

## Step 6: If terraform plan Shows Changes

**Problem**: terraform.tfvars values don't match AWS reality

**Solution**:

`
# 1. Check what changes terraform wants to make
terraform plan -out=tfplan
terraform show tfplan

# 2. Find the difference
# Example: If terraform shows "change subnet CIDR from X to Y"
# → Update terraform.tfvars to match AWS value

# 3. Update terraform.tfvars
# Edit terraform.tfvars with correct values

# 4. Run plan again
terraform plan

# 5. Repeat until "0 changes"
`

**Common Issues**:

Issue: terraform wants to change instance type
- Cause: Instance type in terraform.tfvars doesn't match AWS
- Fix: Run: aws ec2 describe-instances --instance-ids i-xxxxx
- Copy instance type from "InstanceType" field
- Update app_instance_type in terraform.tfvars

Issue: terraform wants to change subnet CIDR
- Cause: CIDR in terraform.tfvars doesn't match AWS
- Fix: Run: aws ec2 describe-subnets --subnet-ids subnet-xxxxx
- Copy CIDR from "CidrBlock" field
- Update the corresponding _subnet_cidr in terraform.tfvars

Issue: terraform wants to remove resources
- Cause: Resource naming or structure doesn't match Terraform modules
- Fix: Check module outputs to see what it expects
- Verify resource was created correctly in AWS

---

## Step 7: Commit to Git (Optional but Recommended)

`
# Check what will be committed
git status

# Add state files (if using local state)
git add terraform.tfstate
git add terraform.tfvars

# Commit
git commit -m "Import: Add existing infrastructure to Terraform management"
`

---

## Complete Workflow Summary

1. Gather all resource IDs from AWS Console
2. Update terraform.tfvars with actual values
3. Run: terraform init
4. Run: terraform validate (should pass)
5. Run: terraform import for each resource (in dependency order)
   - VPC first
   - Subnets
   - Security Groups
   - Load Balancer
   - Auto Scaling Groups
6. Run: terraform plan
7. Check result:
   - If "0 changes" → SUCCESS ✅
   - If shows changes → Fix terraform.tfvars and repeat step 6
8. Continue using terraform for future changes

---

## Troubleshooting Import Issues

### Error: "No valid credential sources found"
- Cause: AWS credentials not configured
- Solution: Run: aws configure
- Enter your Access Key ID and Secret Access Key

### Error: "InvalidParameterValue" during import
- Cause: Resource ID format is incorrect
- Solution: Double-check the ID format matches:
  - VPC ID: vpc-xxxxxxxx
  - Subnet ID: subnet-xxxxxxxx
  - Security Group ID: sg-xxxxxxxx
  - Instance ID: i-xxxxxxxx
  - ASG Name: exactly-as-shown-in-aws

### Error: "Resource already exists in state"
- Cause: Already imported this resource
- Solution: Check with: terraform state list
- If it's already there, that's OK

### terraform plan shows many changes
- Cause: terraform.tfvars values don't match AWS reality
- Solution:
  1. For each resource in AWS, verify the value
  2. Update terraform.tfvars to match
  3. Run terraform plan again
  4. Repeat until "0 changes"

---

## Best Practices for Import

1. Import in dependency order - VPC → Subnets → Security Groups → Load Balancer → Instances
2. Verify after each import - Run terraform state show to confirm
3. Run terraform plan frequently - Check for unexpected changes
4. Keep terraform.tfvars in sync - Any manual AWS changes must be reflected in tfvars
5. Document everything - Why each value was chosen, special configurations, etc.

---

## After Successful Import

✅ All resources are now in Terraform state  
✅ terraform plan shows "0 changes"  
✅ Terraform is now the source of truth for your infrastructure  
✅ Future changes should go through Terraform (not manual AWS changes)

**Next Steps:**
- Deploy changes via Terraform
- Keep tfvars and code updated
- Use Terraform for all infrastructure changes
- Ready for audit documentation

---

**Last Updated**: 2026-11-16  
**Purpose**: Import existing manual infrastructure into Terraform state file  
**Status**: Ready for use
