# Dev Environment - Quick Start Guide

## 📁 Files Created

Your dev environment is now complete with **6 Terraform files**:

```
terraform/environments/dev/
├── versions.tf         (Terraform & AWS provider setup)
├── variables.tf        (40+ configurable variables)
├── main.tf             (5 modules orchestration)
├── outputs.tf          (20+ output values)
├── terraform.tfvars    (YOUR CONFIGURATION - UPDATE REQUIRED!)
└── README.md           (Complete deployment guide)
```

---

## 🚀 Quick Start (3 Steps)

### Step 1: Update Configuration

Edit `terraform/environments/dev/terraform.tfvars`:

**MUST UPDATE:**
```hcl
# Get your SSL certificate ARN from AWS Certificate Manager
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/YOUR-ID"

# Replace 0.0.0.0/0 with actual authorized IPs (PCI-DSS requirement!)
authorized_alb_cidrs = [
  "203.0.113.5/32",          # Your office IP
  "198.51.100.0/24",         # VPN subnet
]
```

**OPTIONAL BUT RECOMMENDED:**
```hcl
secureweb_egress_cidr = "198.51.100.0/24"       # secureweb.com IP range
repository_egress_cidr = "203.0.113.0/24"       # repository.example.com IP range
```

### Step 2: Deploy

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# See what will be created
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 3: Verify

```bash
# See deployment results
terraform output

# Example output:
# alb_dns_name = "payment-poc-dev-alb-1234.elb.amazonaws.com"
# vpc_id = "vpc-abc123"
# app_subnet_id = "subnet-xyz789"
```

---

## 📊 What Gets Created

```
1 VPC + 3 Subnets
├── Public subnet (10.0.1.0/24) → ALB
├── App subnet (10.0.10.0/24) → Application servers
└── Database subnet (10.0.20.0/24) → Database servers

3 Security Groups
├── ALB: Restricted HTTPS access
├── App: Port 8080 from ALB only
└── Database: Port 3306 from App only

2 EC2 Instances (via Auto Scaling Groups)
├── Application server (t3.medium)
└── Database server (t3.medium)

1 Application Load Balancer
├── HTTPS listener (with your SSL certificate)
└── Target group pointing to app servers
```

---

## 🔐 PCI-DSS Compliance

Your deployment addresses:

✅ **PCI-DSS 1.3.1:** Network Segmentation
   - 3-tier architecture separates ALB, App, and Database

✅ **PCI-DSS 1.3.2:** Access Control Lists
   - Inbound: Only authorized IPs → ALB
   - Within VPC: App talks to DB only
   - Outbound: App to specific services only

---

## 📝 Configuration Variables

### Network
- `vpc_cidr = "10.0.0.0/16"` - VPC CIDR block
- `public_subnet_cidr = "10.0.1.0/24"` - ALB subnet
- `app_subnet_cidr = "10.0.10.0/24"` - App tier (private)
- `db_subnet_cidr = "10.0.20.0/24"` - Database tier (private)

### Security
- `authorized_alb_cidrs` - Restricted IP list (PCI-DSS 1.3.2)
- `secureweb_egress_cidr` - IP range for secureweb.com
- `repository_egress_cidr` - IP range for package repository

### Compute
- `app_instance_type = "t3.medium"` - App server size
- `db_instance_type = "t3.medium"` - Database server size

### Auto Scaling
- `asg_min_size = 1` - Minimum instances
- `asg_max_size = 1` - Maximum instances
- `asg_desired_capacity = 1` - Desired instances (1 = single instance for POC)

---

## 🔄 Import Existing Manual Resources (Optional)

If you have existing manual infrastructure in AWS:

1. Set in `terraform.tfvars`:
   ```hcl
   import_existing_resources = true
   
   existing_vpc_id = "vpc-12345678"
   existing_public_subnet_id = "subnet-xxxxxxx"
   existing_app_subnet_id = "subnet-yyyyyyy"
   existing_db_subnet_id = "subnet-zzzzzzz"
   # ... provide all existing resource IDs
   ```

2. Run import commands:
   ```bash
   terraform import aws_vpc.main vpc-12345678
   terraform import aws_subnet.public subnet-xxxxxxx
   # ... etc for other resources
   ```

3. Verify sync:
   ```bash
   terraform plan
   # Should show: No changes. Infrastructure is up-to-date.
   ```

---

## ⚙️ Advanced Configuration

### Custom User Data Scripts

Modify the application installation:

```hcl
app_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y nodejs
npm install -g pm2
# ... your app setup
EOF
```

### Database Configuration

Customize MySQL setup:

```hcl
db_user_data = <<-EOF
#!/bin/bash
yum install -y mysql-server
systemctl start mysqld
# ... your database setup
EOF
```

### Tags

Add custom tags to all resources:

```hcl
tags = {
  Project     = "pci-dss-compliance"
  Environment = "dev"
  Purpose     = "POC"
  Owner       = "DevOps Team"
  CostCenter  = "12345"
}
```

---

## 🧪 Validation Checklist

Before deploying, verify:

- [ ] Terraform installed (v1.0+)
- [ ] AWS credentials configured (`aws configure`)
- [ ] SSL certificate created in AWS ACM
- [ ] Certificate ARN obtained
- [ ] Authorized IPs identified
- [ ] External service IPs identified
- [ ] `terraform.tfvars` updated with all required values

---

## 📚 Documentation

For more details, see:

1. **Full Deployment Guide:**
   `terraform/environments/dev/README.md`

2. **Module Documentation:**
   `terraform/modules/*/README.md`

3. **Architecture Details:**
   `docs/Solution_Assessment.md`

4. **Import Workflow:**
   `docs/Import_Workflow_With_Variables.md`

---

## 🛠️ Common Commands

```bash
# Navigate to dev environment
cd terraform/environments/dev

# Initialize (run once)
terraform init

# Validate syntax
terraform validate

# See what will be created
terraform plan

# Deploy infrastructure
terraform apply

# See current outputs
terraform output

# See specific output
terraform output alb_dns_name

# Destroy infrastructure (cleanup)
terraform destroy

# Format code
terraform fmt

# Save plan for review
terraform plan -out=tfplan
terraform apply tfplan
```

---

## 🚨 Troubleshooting

### "Certificate not found"
- Get ARN from AWS Console → Certificate Manager
- Copy full ARN to `ssl_certificate_arn` in terraform.tfvars

### "Insufficient permissions"
- Check AWS credentials: `aws sts get-caller-identity`
- Reconfigure: `aws configure`

### "Instance won't start"
- Check instance type available in region
- Verify AMI exists in region
- Check security group allows ports

### "Can't access ALB"
- Wait 2-3 minutes for ALB to be ready
- Check ALB DNS name: `terraform output alb_dns_name`
- Verify your IP is in `authorized_alb_cidrs`

---

## 📞 Support

If you need help:

1. Check the README.md in this directory
2. Review module READMEs in `terraform/modules/*/`
3. Check documentation in `docs/` folder
4. Review Terraform logs: `TF_LOG=DEBUG terraform plan`

---

## ✅ You're Ready!

Your dev environment is fully configured. 

**Next steps:**
1. Update `terraform.tfvars` with your values
2. Run `terraform init`
3. Run `terraform plan` to review
4. Run `terraform apply` to deploy

🚀 **Happy deploying!**
