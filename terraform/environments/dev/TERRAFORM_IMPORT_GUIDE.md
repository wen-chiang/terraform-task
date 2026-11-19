# Terraform Import Guide (Dev Environment)

Use this guide when AWS resources already exist and must be brought under Terraform state for this environment.

## Goal

Import existing resources into this module layout without unexpected drift:

- `module.vpc`
- `module.security_groups`
- `module.load_balancer`
- `module.app_server`
- `module.database_server`

## Before import

1. Update [terraform.tfvars](./terraform.tfvars) to match real AWS values:
   - VPC CIDR and subnet CIDRs
   - `authorized_alb_cidrs`
   - instance types and capacity settings
   - certificate ARN and egress CIDRs
2. Initialize Terraform:

```powershell
cd C:\Wrok_Zone\Temp\terraform-task\terraform\environments\dev
terraform init
```

3. Collect all AWS IDs/ARNs first:
   - VPC ID
   - public subnet ID
   - app subnet ID
   - database subnet ID
   - ALB SG ID
   - app SG ID
   - database SG ID
   - ALB ARN
   - target group ARN
   - app launch template ID and ASG name
   - db launch template ID and ASG name

## Import commands

Run each command with real IDs:

```powershell
# VPC and subnets
terraform import module.vpc.aws_vpc.this vpc-xxxxxxxx
terraform import 'module.vpc.aws_subnet.public[0]' subnet-publicxxxxxxxx
terraform import 'module.vpc.aws_subnet.private[0]' subnet-appxxxxxxxx
terraform import 'module.vpc.aws_subnet.private[1]' subnet-dbxxxxxxxx

# Security groups
terraform import module.security_groups.aws_security_group.alb sg-albxxxxxxxx
terraform import module.security_groups.aws_security_group.app sg-appxxxxxxxx
terraform import module.security_groups.aws_security_group.db sg-dbxxxxxxxx

# Load balancer and target group
terraform import 'module.load_balancer.aws_lb.this[0]' arn:aws:elasticloadbalancing:...
terraform import 'module.load_balancer.aws_lb_target_group.this["app"]' arn:aws:elasticloadbalancing:...:targetgroup/...

# App compute
terraform import 'module.app_server.aws_launch_template.this[0]' lt-appxxxxxxxx
terraform import 'module.app_server.aws_autoscaling_group.this[0]' app-asg-name

# Database compute
terraform import 'module.database_server.aws_launch_template.this[0]' lt-dbxxxxxxxx
terraform import 'module.database_server.aws_autoscaling_group.this[0]' db-asg-name
```

## Verify state and drift

```powershell
terraform state list
terraform plan
```

Expected result:

- Imported addresses appear in `terraform state list`.
- `terraform plan` shows only intended differences.

If plan shows unexpected changes:

1. Compare planned values with real AWS values.
2. Correct mismatched values in [terraform.tfvars](./terraform.tfvars).
3. Re-run `terraform plan`.
4. Repeat until stable.

## Common issues

### Credentials error

- Verify caller identity:

```powershell
aws sts get-caller-identity
```

- Reconfigure credentials/profile if needed.

### Wrong import address

- Use exact module/resource addresses from this guide.
- Re-check list indexes and target-group key `"app"`.

### Resource already in state

- Confirm with `terraform state list`.
- If mapped incorrectly, remove only the wrong state entry and re-import the correct one.

## Final step

After stable plan:

```powershell
terraform apply
```

Then verify outputs:

```powershell
terraform output
```
