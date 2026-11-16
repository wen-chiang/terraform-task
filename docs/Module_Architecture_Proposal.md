# Terraform Module Architecture Proposal

## Executive Summary

This document outlines the recommended Terraform module structure for implementing the PCI-DSS compliant infrastructure on AWS. The proposed architecture uses **5 core modules** organized for maximum reusability, maintainability, and compliance enforcement.

---

## Proposed Module Structure

### Directory Layout

```
terraform/
├── modules/
│   ├── vpc/                       # Network foundation (VPC + Subnets)
│   ├── security_groups/           # Access control rules (SGs for ALB, App, DB)
│   ├── ec2_app/                   # Application server instance
│   ├── ec2_database/              # MySQL database server instance
│   ├── alb/                       # Application Load Balancer + SSL
│   └── asg/                       # Auto Scaling Group (optional)
│
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
│
├── main.tf                        # Root module orchestration
├── variables.tf                   # Input variables
├── outputs.tf                     # Output values
├── terraform.tfvars              # Variable values
└── README.md
```

---

## Module Details

### 1. **VPC Module** 🌐

**Purpose**: Create the network foundation  
**Responsibility**: 
- Create VPC with CIDR block
- Create 3 subnets (public, private/app, private/database)
- Create Internet Gateway (IGW)
- Create NAT Gateway for private subnet egress
- Create route tables and associations

**Inputs**:
```hcl
vpc_cidr
public_subnet_cidr
app_subnet_cidr
db_subnet_cidr
region
environment
```

**Outputs**:
```hcl
vpc_id
public_subnet_id
app_subnet_id
db_subnet_id
nat_gateway_ip
```

**Why This Module?**
- Core foundation for all network resources
- Reusable across dev/staging/production
- Easy to adjust CIDR blocks per environment

---

### 2. **Security Groups Module** 🔒

**Purpose**: Implement PCI-DSS network segmentation (1.3.1, 1.3.2)  
**Responsibility**:
- Create ALB security group (inbound: 80/443 from restricted IPs)
- Create App security group (inbound: from ALB only)
- Create Database security group (inbound: from App only)
- Define egress rules for outbound communication

**Inputs**:
```hcl
vpc_id
alb_allowed_cidrs           # Finite list of IPs
secureweb_cidr              # secureweb.com IP range
repository_cidr             # repository.example.com IP range
app_instance_sg_id
db_instance_sg_id
```

**Outputs**:
```hcl
alb_security_group_id
app_security_group_id
db_security_group_id
```

**Why This Module?**
- Centralizes security rules (critical for PCI-DSS compliance)
- Easy to audit and update access policies
- Separation of concerns for different tiers

---

### 3. **EC2 App Module** 💻

**Purpose**: Deploy application server  
**Responsibility**:
- Create EC2 instance (Linux)
- Attach security group
- Create IAM role for EC2 access to systems
- Configure user-data script for package installation
- Attach to target group (ALB)
- Configure monitoring/tags

**Inputs**:
```hcl
instance_type               # e.g., t3.medium
ami_id                      # Latest Amazon Linux 2
subnet_id                   # app_subnet_id
security_group_id
user_data_script            # Installation commands
repository_url              # repository.example.com
alb_target_group_arn
environment
```

**Outputs**:
```hcl
instance_id
private_ip
instance_role_arn
```

**Why This Module?**
- Encapsulates app-specific configuration
- User-data script handles package installation
- Supports IAM roles for secure service communication

---

### 4. **EC2 Database Module** 🗄️

**Purpose**: Deploy MySQL database server  
**Responsibility**:
- Create EC2 instance (Linux)
- Attach database security group
- Install and configure MySQL
- Create IAM role for backups
- Configure monitoring/tags

**Inputs**:
```hcl
instance_type               # e.g., t3.large (larger than app)
ami_id                      # Latest Amazon Linux 2
subnet_id                   # db_subnet_id (private)
security_group_id
db_name
db_user
db_password
root_volume_size
environment
```

**Outputs**:
```hcl
instance_id
private_ip
instance_role_arn
db_security_group_id
```

**Why This Module?**
- Isolated database configuration
- Private subnet placement for security
- Easier to manage database-specific settings

---

### 5. **ALB Module** ⚖️

**Purpose**: Expose application through load balancer with SSL  
**Responsibility**:
- Create Application Load Balancer
- Create target groups for app instances
- Attach SSL/TLS certificate
- Configure listener rules (HTTP redirect, HTTPS)
- Configure health checks

**Inputs**:
```hcl
vpc_id
subnet_ids                  # public_subnet_id
security_group_id
app_target_group_name
ssl_certificate_arn         # ACM certificate
alb_name
environment
```

**Outputs**:
```hcl
alb_dns_name
alb_id
target_group_arn
target_group_id
```

**Why This Module?**
- Centralizes load balancer configuration
- SSL termination at ALB (security best practice)
- Easy to modify listener rules or certificates

---

### 6. **ASG Module** (Optional) 🔄

**Purpose**: Enable auto-scaling capability  
**Responsibility**:
- Create Auto Scaling Group
- Create Launch Template (from EC2 app module)
- Configure min/max capacity
- Define scaling policies
- Create CloudWatch alarms

**Inputs**:
```hcl
launch_template_id
launch_template_version
min_size
max_size
desired_capacity
target_group_arn
health_check_type
environment
```

**Outputs**:
```hcl
asg_id
asg_name
```

**Why This Module?**
- Optional but ready for production use
- Can be skipped for POC (replace with single EC2)
- Easy to add later without refactoring

---

## Module Interaction Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      ROOT MODULE (main.tf)                   │
│  Orchestrates all modules and manages dependencies           │
└──────────┬──────────────────────────────────────────────────┘
           │
      ┌────┴──────┬──────────┬────────────┬──────────┬────────┐
      │            │          │            │          │        │
      ▼            ▼          ▼            ▼          ▼        ▼
   ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌───────┐ ┌────────┐ ┌───────┐
   │   VPC   │ │   SGs    │ │EC2 App  │ │EC2 DB │ │  ALB   │ │  ASG  │
   │ Module  │ │ Module   │ │ Module  │ │Module │ │Module  │ │Module │
   │         │ │          │ │         │ │       │ │        │ │       │
   │·VPC     │ │·ALB SG   │ │·Instance│ │·      │ │·LB     │ │·Launch│
   │·Subnets │ │·App SG   │ │·IAM     │ │Instance│ │·Target │ │Template│
   │·IGW     │ │·DB SG    │ │·UserData│ │·IAM   │ │Groups  │ │·Min/Max│
   │·NAT GW  │ │          │ │·Tags    │ │·Tags  │ │·SSL    │ │·Scaling│
   └────┬────┘ └────┬─────┘ └────┬────┘ └───┬───┘ └───┬────┘ └──┬─────┘
        │            │            │          │        │         │
        └────────────┴────────────┴──────────┴────────┴─────────┘
                     All modules output values to root
```

---

## Comparison: Module Approaches

### Option 1: 5 Modules (RECOMMENDED) ⭐

**Pros:**
- ✅ Highly modular and reusable
- ✅ Clear separation of concerns
- ✅ Easy to maintain and test individually
- ✅ Scales well for multi-environment deployments
- ✅ Security best practices (SGs isolated)

**Cons:**
- ❌ Slightly more files to manage
- ❌ More complex initially

---

### Option 2: 3 Modules (Minimal)

**Structure:**
```
├── modules/
│   ├── networking/     # VPC + SGs
│   ├── compute/        # EC2 App + DB
│   └── alb/           # Load Balancer
```

**Pros:**
- ✅ Simpler structure
- ✅ Fewer files

**Cons:**
- ❌ Less modular
- ❌ Harder to reuse in different contexts
- ❌ Mixing security concerns
- ❌ Not recommended for PCI-DSS

---

### Option 3: 1 Monolithic Module (NOT RECOMMENDED) ❌

**Cons:**
- ❌ Not reusable
- ❌ Hard to maintain
- ❌ Difficult to test
- ❌ Not scalable
- ❌ Poor separation of concerns

---

## Why 5 Modules is Best for PCI-DSS

| Requirement | Addressed By |
|-------------|-------------|
| Network Segmentation (1.3.1) | Separate VPC + Subnet modules |
| Access Control Lists (1.3.2) | Dedicated SGs module |
| Repeatable Configuration | Modular approach |
| Auditability | Each module has clear responsibilities |
| Scalability | Easy to add environments/features |
| Security Best Practices | Separated concerns |

---

## Implementation Phases

### Phase 1: Core Modules (Days 1-2)
- VPC module
- Security Groups module
- EC2 App module
- EC2 Database module

### Phase 2: Integration (Day 3)
- ALB module
- Module orchestration in main.tf
- Testing and validation

### Phase 3: Optional Enhancements (Days 4-5)
- ASG module (optional)
- Terraform state management
- CI/CD pipeline preparation
- Audit documentation

---

## Module Reusability Matrix

| Use Case | Reusable Modules |
|----------|------------------|
| Local Development | All 5 |
| Development Environment | All 5 |
| Staging Environment | All 5 |
| Production (Multi-AZ) | All 5 (with adjustments) |
| Disaster Recovery | All 5 |
| POC to Production | All 5 (no refactoring needed) |

---

## Recommended Next Steps

1. ✅ Approve module architecture
2. 📝 Create module templates with variable definitions
3. 🔧 Implement VPC module first (foundation)
4. 🔒 Implement Security Groups module (PCI-DSS critical)
5. 💻 Implement EC2 modules
6. ⚖️ Implement ALB module
7. 🧪 Test infrastructure deployment
8. 📊 Create infrastructure diagram
9. 📋 Prepare audit documentation

---

## Success Criteria

✅ All 5 modules created and functional  
✅ Modules are reusable across environments  
✅ Security groups implement access control  
✅ Infrastructure deployable via single `terraform apply`  
✅ Clear separation of concerns  
✅ Ready for audit review  

---

---

## Managing Existing Manual Infrastructure

### Current Situation

The infrastructure currently exists as **manual resources** created directly in AWS Console:

```
Current Manual State:
├── VPC (manually created)
├── 3 Subnets (manually created)
├── Security Groups (manually created)
├── EC2 App Instance (manually created)
├── EC2 Database Instance (manually created)
└── ALB (manually created)

Challenge: ❌ No automation, No Terraform code, Hard to replicate
Solution: Bring manual resources under Terraform management
```

---

### Three Options to Handle Manual Build

#### Option A: **Import Existing Infrastructure** ⭐⭐⭐ RECOMMENDED

**What it means:**
- Keep existing manual infrastructure running (NO DOWNTIME)
- Write Terraform code for all resources
- Use `terraform import` to bring them under management
- Terraform now "owns" and manages the infrastructure

**How it works:**
```
Step 1: Create Terraform modules (days 1-3)
Step 2: Identify manual resource IDs in AWS Console
Step 3: Run terraform import commands
Step 4: Terraform state now contains existing resources
Step 5: Manage everything via Terraform going forward
```

**Example Import Commands:**
```bash
# Import VPC
terraform import aws_vpc.main vpc-12345678

# Import Subnets
terraform import aws_subnet.public subnet-xxxxxxx
terraform import aws_subnet.app subnet-xxxxxxx
terraform import aws_subnet.db subnet-xxxxxxx

# Import Security Groups
terraform import aws_security_group.alb sg-xxxxxxx
terraform import aws_security_group.app sg-xxxxxxx
terraform import aws_security_group.db sg-xxxxxxx

# Import EC2 Instances
terraform import aws_instance.app i-xxxxxxxxxxxxxxx
terraform import aws_instance.db i-xxxxxxxxxxxxxxx

# Import ALB
terraform import aws_lb.main arn:aws:elasticloadbalancing:...
```

**Pros:**
- ✅ **No downtime** - existing infrastructure stays running
- ✅ **Fast for audit deadline** - import takes 1-2 hours
- ✅ **Lower risk** - fallback to manual if needed
- ✅ **Audit-friendly** - shows migration to automation
- ✅ **Reversible** - can destroy and recreate safely

**Cons:**
- ⚠️ Manual resources must exist first
- ⚠️ Import can be tedious for many resources
- ⚠️ Manual resource IDs must be identified

**Time Required:** 2-4 hours (after Terraform code written)

---

#### Option B: **Destroy & Rebuild (Clean Slate)**

**What it means:**
- Delete all existing manual infrastructure completely
- Deploy brand new infrastructure via Terraform
- Completely fresh start from scratch

**Process:**
```
Step 1: Document all existing manual configuration
Step 2: Create Terraform code (5-8 hours)
Step 3: Destroy manual infrastructure (AWS Console)
Step 4: Run: terraform apply
Step 5: New infrastructure deployed
```

**Pros:**
- ✅ Clean, fresh infrastructure
- ✅ No messy imports to manage
- ✅ Pure Terraform from day 1
- ✅ Repeatable and consistent

**Cons:**
- ❌ **Requires downtime** - services interrupted
- ❌ Longer total timeline (8-12 hours)
- ❌ Risky for audit deadline
- ❌ Not recommended under time pressure

**Time Required:** 8-12 hours total

---

#### Option C: **Keep Manual + Build Parallel (NOT RECOMMENDED)**

**What it means:**
- Keep existing manual infrastructure running
- Build new Terraform infrastructure simultaneously
- After audit, migrate to Terraform version

**Pros:**
- ✅ No disruption
- ✅ Time to test

**Cons:**
- ❌ Duplicate resources (expensive)
- ❌ Confusing for audit review
- ❌ Complex resource management
- ❌ Not recommended

**Time Required:** 12+ hours

**Status:** ❌ **NOT RECOMMENDED**

---

### Option Comparison Matrix

| Criteria | Option A: Import | Option B: Rebuild | Option C: Parallel |
|----------|------------------|------------------|-------------------|
| **Time Required** | 2-4 hours | 8-12 hours | 12+ hours |
| **Downtime** | ❌ None | ⚠️ Yes (2-4 hrs) | ❌ None |
| **Complexity** | ⭐⭐ Medium | ⭐ Easy | ⭐⭐⭐ Hard |
| **Audit Ready** | ✅ Day 4-5 | ✅ Day 5 | ❌ Not ready |
| **Risk Level** | 🟢 Low | 🔴 High | 🟡 Medium |
| **Recommended** | ⭐⭐⭐ YES | ❌ No | ❌ No |
| **Best For** | 5-day deadline | No time pressure | Not viable |

---

### RECOMMENDATION: Use Option A (Import) ⭐⭐⭐

**Why Import is Best:**

1. **Perfect for 5-day audit deadline** ✅
   - Existing infrastructure continues running
   - Write Terraform in parallel (days 1-3)
   - Import when ready (day 4)
   - Zero downtime
   - Ready for audit day 5

2. **Audit-friendly approach** ✅
   - Shows infrastructure automation progress
   - Demonstrates compliance enforcement
   - Migration path visible to auditors

3. **Lower implementation risk** ✅
   - No service disruption
   - Existing data protected
   - Fallback to manual always available

4. **Faster overall timeline** ✅
   - Terraform code: days 1-3
   - Import: day 4
   - Testing/audit prep: day 5

---

### Recommended Implementation Timeline (Option A)

```
Day 1-2: Create Terraform Modules
├── Write VPC module
├── Write Security Groups module
├── Write EC2 App module
├── Write EC2 Database module
├── Write ALB module
└── All modules ready, not yet deployed

Day 3:   Terraform Code Validation
├── terraform plan (review output)
├── Verify all resources match manual setup
├── Identify all manual resource IDs

Day 4:   Import Existing Infrastructure
├── Run terraform import commands
├── Verify terraform state accuracy
├── Run terraform plan (should show 0 changes)
├── All manual resources now managed by Terraform

Day 5:   Audit Preparation
├── Final testing and validation
├── Documentation and diagram
├── Audit readiness review
└── Ready for external audit
```

---

### Import Process Detailed Steps

#### Step 1: Gather Manual Resource IDs

Create a checklist of all manual resources:

| Resource | Type | ID/ARN | Location |
|----------|------|--------|----------|
| Payment VPC | VPC | vpc-xxxxxxxx | AWS Console → VPCs |
| Public Subnet | Subnet | subnet-xxxxxxxx | AWS Console → Subnets |
| App Subnet | Subnet | subnet-xxxxxxxx | AWS Console → Subnets |
| Database Subnet | Subnet | subnet-xxxxxxxx | AWS Console → Subnets |
| ALB Security Group | SG | sg-xxxxxxxx | AWS Console → Security Groups |
| App Security Group | SG | sg-xxxxxxxx | AWS Console → Security Groups |
| DB Security Group | SG | sg-xxxxxxxx | AWS Console → Security Groups |
| App Instance | EC2 | i-xxxxxxxxxxxxxxx | AWS Console → Instances |
| Database Instance | EC2 | i-xxxxxxxxxxxxxxx | AWS Console → Instances |
| Load Balancer | ALB | arn:aws:... | AWS Console → Load Balancers |
| Internet Gateway | IGW | igw-xxxxxxxx | AWS Console → Internet Gateways |
| NAT Gateway | NAT | natgw-xxxxxxxx | AWS Console → NAT Gateways |

#### Step 2: Create Terraform Code

Write all modules with matching resource names:

```hcl
# Example: vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "payment-vpc"
  }
}

# Example: security_groups/main.tf
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id
}
```

#### Step 3: Run Import Commands

```bash
cd terraform/

# Import VPC
terraform import aws_vpc.main vpc-12345678

# Import Subnets
terraform import module.vpc.aws_subnet.public subnet-xxxxxxx
terraform import module.vpc.aws_subnet.app subnet-xxxxxxx
terraform import module.vpc.aws_subnet.db subnet-xxxxxxx

# Import Security Groups
terraform import module.security_groups.aws_security_group.alb sg-xxxxxxx
terraform import module.security_groups.aws_security_group.app sg-xxxxxxx
terraform import module.security_groups.aws_security_group.db sg-xxxxxxx

# Import EC2 Instances
terraform import module.ec2_app.aws_instance.app i-xxxxxxxxxxxxxxx
terraform import module.ec2_database.aws_instance.db i-xxxxxxxxxxxxxxx

# Import ALB
terraform import module.alb.aws_lb.main arn:aws:elasticloadbalancing:...
```

#### Step 4: Verify Import Success

```bash
# Check terraform state
terraform state list
# Output: should show all imported resources

# Plan to ensure no changes
terraform plan
# Output: should show "No changes. Infrastructure is up-to-date."
```

---

### How to Find Manual Resource IDs

#### Finding VPC ID
```
AWS Console → VPC Dashboard → Your VPCs
Example: vpc-12345678
```

#### Finding Subnet IDs
```
AWS Console → VPC Dashboard → Subnets
Example: subnet-xxxxxxxx (3 subnets total)
```

#### Finding Security Group IDs
```
AWS Console → EC2 → Security Groups
Example: sg-xxxxxxxx (3 security groups)
```

#### Finding EC2 Instance IDs
```
AWS Console → EC2 → Instances
Example: i-xxxxxxxxxxxxxxx (2 instances)
```

#### Finding ALB ARN
```
AWS Console → EC2 → Load Balancers
Example: arn:aws:elasticloadbalancing:region:account-id:loadbalancer/app/name/id
```

---

### Post-Import Workflow

After successful import:

```
Step 1: All manual resources now in Terraform state
Step 2: Can make changes via Terraform going forward
Step 3: `terraform apply` to modify infrastructure
Step 4: `terraform destroy` could destroy all resources (use with caution!)
Step 5: Fully automated, repeatable infrastructure
```

---

### Import Troubleshooting

| Issue | Solution |
|-------|----------|
| Resource already in state | Remove from state first: `terraform state rm <resource>` |
| Import fails with 404 | Verify resource ID is correct and in same region |
| State file conflicts | Check Terraform is in correct directory |
| Wrong resource matched | Use full resource ID path in import command |

---

## Updated Approval Checklist

- [ ] Agree with 5-module architecture
- [ ] Confirm module responsibilities
- [ ] Approve phase-based implementation
- [ ] Choose infrastructure handling approach (Import recommended)
- [ ] Gather manual resource IDs (if importing)
- [ ] Ready to proceed with Terraform modules
- [ ] Ready to proceed with import process (if applicable)
