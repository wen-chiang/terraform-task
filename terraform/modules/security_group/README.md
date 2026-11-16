# security_group module

## Resource identity

- **Abbreviated name:** `security_group` 
- **Full name:** Amazon VPC Security Groups

## Purpose

Creates baseline application and database security groups for workload segmentation and least privilege.

Creates baseline application and database security groups.

## 1) Incoming info (inputs)

### 1.1 Required common inputs (from `modules/common`)

| Input | Type | Source |
|---|---|---|
| `naming_prefix` | `string` | `module.common.naming_prefix` |
| `tags` | `map(string)` | `module.common.tags` |

### 1.2 Module-specific inputs

| Input | Type | Required | Purpose |
|---|---|---:|---|
| `vpc_id` | `string` | Yes | VPC target for SGs |
| `resource_name` | `string` | No | Naming suffix |
| `app_ingress_rules` | `list(object)` | No | App ingress rules |
| `app_egress_rules` | `list(object)` | No | App egress rules |
| `db_port` | `number` | No | DB ingress port from app SG |

---

## 2) Referenced resource info

### 2.1 Upstream module references

- Typically consumes `vpc_id` from `module.vpc.vpc_id`.
- Uses common naming/tag outputs from `module.common`.

### 2.2 AWS resources created by this module

| Resource | Terraform Address |
|---|---|
| App Security Group | `aws_security_group.app` |
| DB Security Group | `aws_security_group.db` |
| App ingress rules | `aws_security_group_rule.app_ingress` |
| App egress rules | `aws_security_group_rule.app_egress` |
| DB ingress from app | `aws_security_group_rule.db_ingress_from_app` |
| DB egress all | `aws_security_group_rule.db_egress_all` |

---

## 3) Output info (for downstream references)

| Output | Type | Downstream usage |
|---|---|---|
| `app_sg_id` | `string` | Attach to compute/app resources |
| `db_sg_id` | `string` | Attach to DB resources |





