# DevOps Task: PCI-DSS Compliance Infrastructure on AWS

## Task Overview

**Objective**: Design and implement an infrastructure solution to address PCI-DSS certification compliance gaps (specifically points 1.3.1 and 1.3.2) for a Payment Provider startup using Terraform on AWS.

**Timeline**: 5 days until external audit  
**Current State**: Manual infrastructure with no automation

---

## Context

### Company Profile
- Simulated Payment Provider startup company
- Goal: Pass PCI-DSS certification to acquire new customers
- Audit Finding: Points 1.3.1 and 1.3.2 not properly addressed in infrastructure design

### Key Terminology
- **CDE** (Cardholder Data Environment): The network segment handling payment card data

---

## Current Infrastructure

### Components
The existing infrastructure running inside a VPC consists of:

| Component | Details |
|-----------|---------|
| **App Server** | EC2 Linux instance (single instance in Auto Scaling Group) |
| **Database** | EC2 Linux MySQL instance |
| **Network** | 3 Subnets in default VPC |
| **Load Balancer** | ALB with external IP and SSL certificate attached |
| **Security Groups** | Default outbound rules; inbound port 80 from 0.0.0.0/0 |

### Application Requirements

**Startup Process:**
- Instance startup script installs packages from `repository.example.com`
- Application won't start without required packages

**Daily Operations:**
- Must communicate with `secureweb.com` over HTTPS
- Inbound traffic must be limited to a **finite list of authorized IP addresses** (not open to the world)

### Current Issues

1. **No Infrastructure Automation** - All resources created manually
2. **Overly Permissive Security** - Inbound traffic open to 0.0.0.0/0
3. **Non-Compliant Access Control** - Doesn't meet PCI-DSS points 1.3.1 and 1.3.2
4. **No Disaster Recovery** - Manual infrastructure can't be quickly reprovisioned for audit

---

## Tasks to Complete

### 1. **Create Terraform Code** ⭐ (Primary Deliverable)
Create Infrastructure-as-Code that includes:
- VPC and 3 Subnets
- Security Groups with proper inbound/outbound rules
- EC2 Linux App Instance
- EC2 Linux MySQL Instance
- Application Load Balancer (ALB) with SSL certificate
- Auto Scaling Group (optional - can be replaced with single EC2)

### 2. **Create Infrastructure Diagram**
Prepare a simple visual diagram showing:
- VPC layout
- Subnet arrangement
- EC2 instances placement
- ALB configuration
- Security group rules flow

### 3. **Auto Scaling Configuration** (Optional)
- ASG can be skipped
- Alternative: Replace with a single EC2 instance if needed

### 4. **Audit Preparedness Discussion**
Prepare talking points for:
- Alternative solutions if 5-day rollout timeline is at risk
- Quick mitigation strategies
- Phase-based implementation approach
- Risk assessment for external auditors

### 5. **POC Discussion Preparation**
Be ready to discuss:
- POC architecture decisions
- How the solution addresses PCI-DSS 1.3.1 and 1.3.2
- Security improvements over current manual setup
- Scalability and maintainability benefits

---

## PCI-DSS Compliance Focus

### Points 1.3.1 and 1.3.2 Address
These requirements typically relate to:
- **Network segmentation** between different systems and data types
- **Restricting inbound traffic** to only necessary sources and ports
- **Outbound access control** for external communications
- **Configuration standards** applied consistently across infrastructure

### Expected Solutions
- Implement restrictive security group rules
- Separate subnets for different tiers (web/app/database)
- Allowlist-based access from specific IPs
- Egress control to known external services only
- Automated, repeatable infrastructure deployment

---

## Deliverables Checklist

- [ ] Terraform code for complete infrastructure
- [ ] Infrastructure diagram (visual representation)
- [ ] Security group configuration documentation
- [ ] Network segmentation design document
- [ ] Discussion points for audit timeline concerns
- [ ] POC walkthrough notes

---

## Success Criteria

✅ Infrastructure can be deployed via Terraform  
✅ All manual components now automated  
✅ Security groups properly restrict traffic  
✅ Addresses PCI-DSS points 1.3.1 and 1.3.2  
✅ Ready for external audit review  
✅ Repeatable and maintainable for future deployments

---

## Next Steps

1. Review PCI-DSS requirements 1.3.1 and 1.3.2 in detail
2. Design network segmentation strategy
3. Create Terraform modules for reusability
4. Develop infrastructure diagram
5. Prepare audit discussion materials
