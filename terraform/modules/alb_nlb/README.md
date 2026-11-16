# alb_nlb module

## Resource identity

- **Abbreviated name:** `alb_nlb` 
- **Full name:** Elastic Load Balancing (ALB/NLB)

## Purpose

Creates Application/Network Load Balancer resources and target groups for ingress traffic distribution.

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

- Typical depends on: vpc, subnets, sg_baseline

### 2.2 AWS resources created by this module

- Implemented resources are defined in `main.tf` and vary by `module_settings`.

---

## 3) Output info (for downstream references)

| Output | Type | Downstream usage |
|---|---|---|
| `lb_dns_name` | `string` | Downstream reference |
| `target_group_arns` | `map(string)` | Downstream reference |






