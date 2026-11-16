# vpc module

## Resource identity

- **Abbreviated name:** `vpc` 
- **Full name:** Amazon Virtual Private Cloud (VPC)

## Purpose

Builds a VPC network foundation with subnets, routing, gateway options, and company-standard tagging.

Creates VPC baseline resources including subnets, route tables, internet gateway, and optional NAT.

## 1) Incoming info (inputs)

### 1.1 Required common inputs (from `modules/common`)

| Input | Type | Source |
|---|---|---|
| `naming_prefix` | `string` | `module.common.naming_prefix` |
| `tags` | `map(string)` | `module.common.tags` |
| `security_profile` | `object` | `module.common.security_profile` |
| `operations_profile` | `object` | `module.common.operations_profile` |
| `network_defaults` | `object` | `module.common.network_defaults` |

### 1.2 Module-specific inputs

| Input | Type | Required | Purpose |
|---|---|---:|---|
| `cidr_block` | `string` | Yes | VPC CIDR |
| `azs` | `list(string)` | Yes | AZs for subnet placement |
| `public_subnet_cidrs` | `list(string)` | No | Public subnet CIDRs |
| `private_subnet_cidrs` | `list(string)` | No | Private subnet CIDRs |
| `enable_internet_gateway` | `bool` | No | IGW creation toggle |
| `enable_nat_gateway` | `bool` | No | NAT creation toggle |

---

## 2) Referenced resource info

### 2.1 Upstream module references

Directly references `module.common` outputs listed above.

### 2.2 AWS resources created by this module

| Resource | Terraform Address |
|---|---|
| VPC | `aws_vpc.this` |
| Internet Gateway (optional) | `aws_internet_gateway.this` |
| Public Subnets | `aws_subnet.public` |
| Private Subnets | `aws_subnet.private` |
| Public Route Table / Route | `aws_route_table.public`, `aws_route.public_internet` |
| Private Route Table / Route | `aws_route_table.private`, `aws_route.private_nat` |
| Route Table Associations | `aws_route_table_association.public`, `aws_route_table_association.private` |
| NAT EIP / NAT Gateway (optional) | `aws_eip.nat`, `aws_nat_gateway.this` |

---

## 3) Output info (for downstream references)

| Output | Type | Downstream usage |
|---|---|---|
| `vpc_id` | `string` | Input for SG, EKS, RDS, ALB, etc. |
| `vpc_cidr_block` | `string` | Network ACL and route design |
| `public_subnet_ids` | `list(string)` | Public-facing resources |
| `private_subnet_ids` | `list(string)` | Private workloads/data tier |
| `internet_gateway_id` | `string` | Route and ingress wiring |
| `nat_gateway_ids` | `list(string)` | Egress routing references |





