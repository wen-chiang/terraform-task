# common module

## Resource identity

- **Abbreviated name:** `common` 
- **Full name:** Common Company Contract

## Purpose

Defines the central company contract for naming, tagging, security, operations, and network defaults consumed by all other modules.

Central policy and naming contract for all consumer stacks.

## 1) Incoming info (inputs)

### 1.1 Required inputs

| Input | Type | Purpose |
|---|---|---|
| `company_code` | `string` | Company short code in naming |
| `company_name` | `string` | Company display name for tags |
| `environment` | `string` | Environment value in naming and tags |
| `region` | `string` | Region context passed to consumers |
| `owner` | `string` | Owner/team tag value |
| `cost_center` | `string` | CostCenter tag value |
| `project` | `string` | Project tag value |

### 1.2 Optional policy inputs

Examples: `mode`, `compliance_framework`, `enforce_encryption`, `enable_logging`, `required_tag_keys`, `additional_tags`, retention and network defaults.

---

## 2) Referenced resource info

### 2.1 Upstream module references

None. This is the root shared contract module.

### 2.2 AWS resources created by this module

None. This module computes and validates policy objects only.

---

## 3) Output info (for downstream references)

| Output | Type | Downstream usage |
|---|---|---|
| `tags` | `map(string)` | Apply to all resources |
| `naming_prefix` | `string` | Prefix for all module naming |
| `resource_naming_pattern` | `string` | Naming pattern hint |
| `security_profile` | `object` | Shared security defaults |
| `operations_profile` | `object` | Shared operations defaults |
| `network_defaults` | `object` | Shared network defaults |
| `compliance_profile` | `object` | Shared compliance context |





