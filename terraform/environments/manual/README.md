# PCI-DSS Manual Environment (Import-Only Fallback)

This environment is a fast-track fallback for audit readiness when full rollout may exceed five days.

## Objective

1. Apply immediate SG hardening controls.
2. Bring existing manual resources under Terraform management.
3. Produce stable `terraform plan` output with no unexpected drift.

## POC Flow (Target)

```text
Internet (authorized IPs only)
    -> ALB (public subnet)
    -> App EC2/ASG (private subnet)
    -> DB EC2/ASG (private subnet)

App outbound:
- HTTPS 443 to repository.example.com
- HTTPS 443 to secureweb.com
```

## Quick Runbook

```bash
cd terraform/environments/manual
terraform init
terraform plan
```

## Import Workflow (Detailed)

### 1) Collect Resource Inventory

Before import, prepare the exact IDs/ARNs from AWS:

| Resource | Example |
| --- | --- |
| VPC ID | `vpc-xxxxxxxx` |
| Public subnet ID | `subnet-public` |
| App subnet ID | `subnet-app` |
| DB subnet ID | `subnet-db` |
| App/ALB SG ID | `sg-aaaaaaaa` |
| DB SG ID | `sg-bbbbbbbb` |
| ALB ARN | `arn:aws:elasticloadbalancing:...:loadbalancer/app/...` |
| Target group ARN | `arn:aws:elasticloadbalancing:...:targetgroup/...` |
| App launch template ID | `lt-xxxxxxxx` |
| App ASG name | `app-asg-name` |
| DB launch template ID | `lt-yyyyyyyy` |
| DB ASG name | `db-asg-name` |

### 2) Set Variables First

Update [terraform.tfvars](./terraform.tfvars) before importing:

- `authorized_alb_cidrs`
- `secureweb_egress_cidr`
- `repository_egress_cidr`
- subnet CIDRs and naming fields if they differ from current values

Then run:

```bash
terraform plan
```

Review the plan and confirm it reflects the intended target design.

### 3) Import in Dependency Order

Use this order to reduce mismatch errors:

1. VPC and subnets  
2. Security groups  
3. ALB and target group  
4. Launch templates and ASGs

```bash
# VPC and subnets
terraform import module.vpc.aws_vpc.this vpc-xxxxxxxx
terraform import 'module.vpc.aws_subnet.public[0]' subnet-public
terraform import 'module.vpc.aws_subnet.private[0]' subnet-app
terraform import 'module.vpc.aws_subnet.private[1]' subnet-db

# Security groups
terraform import module.security_groups.aws_security_group.app sg-app-or-alb
terraform import module.security_groups.aws_security_group.db sg-db

# ALB and target group
terraform import 'module.load_balancer.aws_lb.this[0]' arn:aws:elasticloadbalancing:...
terraform import 'module.load_balancer.aws_lb_target_group.this["app"]' arn:aws:elasticloadbalancing:...:targetgroup/...

# App/DB ASG and launch templates
terraform import 'module.app_server.aws_launch_template.this[0]' lt-xxxxxxxx
terraform import 'module.app_server.aws_autoscaling_group.this[0]' app-asg-name
terraform import 'module.database_server.aws_launch_template.this[0]' lt-yyyyyyyy
terraform import 'module.database_server.aws_autoscaling_group.this[0]' db-asg-name
```

### 4) Verify Imported State

```bash
terraform state list
terraform plan
```

Expected result:

- `terraform state list` includes all imported addresses.
- `terraform plan` shows no unexpected destructive or replacement changes.

### 5) Reconcile Until Stable

If plan still shows drift:

1. Correct values in [terraform.tfvars](./terraform.tfvars).
2. Re-run `terraform plan`.
3. Repeat until only expected differences remain.

## Common Import Issues

- **Wrong Terraform address**: ensure module path and index/key are exact.
- **Wrong region/account**: confirm AWS CLI profile/region matches imported resources.
- **Name/CIDR mismatch**: align variable values to actual deployed settings.
- **Partial import**: missing one dependency often causes noisy follow-up plans.

## Discussion Notes for Audit

- Immediate risk reduction is achieved by SG hardening first.
- Terraform import provides traceable, repeatable control management.
- Remaining rollout items can proceed in phased execution without losing control evidence.
