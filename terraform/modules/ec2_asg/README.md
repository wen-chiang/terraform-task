# ec2_asg module

## Resource identity

- **Abbreviated name:** `ec2_asg` 
- **Full name:** Amazon EC2 Auto Scaling Group (ASG)

## Purpose

Creates Launch Template and Auto Scaling Group resources for EC2-based compute fleets.

Module aligned to the central contract and creation-order design.

## 1) Incoming info (inputs)

### 1.1 Required common inputs (from modules/common)

| Input | Type | Source |
|---|---|---|
| naming_prefix | string | module.common.naming_prefix |
| tags | map(string) | module.common.tags |
| `security_profile` | `object({ mode=string, enforce_encryption=bool, enable_logging=bool, enforce_tls=bool, encryption_key_arn=string })` | module.common.security_profile |
| `operations_profile` | `object({ backup_retention_days=number, log_retention_days=number, enable_monitoring=bool, enable_detailed_monitoring=bool })` | module.common.operations_profile |
| `network_defaults` | `object({ high_availability=bool, availability_zones=list(string), enable_nat_gateway=bool })` | module.common.network_defaults |

### 1.2 Module-specific inputs

| Input | Type | Required | Purpose |
|---|---|---:|---|
| `module_settings` | `object({...})` | No | Module-specific settings object |

---

## 2) Referenced resource info

### 2.1 Upstream module references

- Typical depends on: subnets, sg_baseline

### 2.2 AWS resources created by this module

- Implemented resources are defined in `main.tf` and vary by `module_settings`.

---

## 3) Output info (for downstream references)

| Output | Type | Downstream usage |
|---|---|---|
| `asg_name` | `string` | Downstream reference |






