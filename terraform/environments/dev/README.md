# Development Environment

This environment creates a three-tier AWS infrastructure for the development proof of concept. Terraform deploys the network, security controls, load balancer, application servers, and database servers.

The architecture separates public, application, and database resources:

```text
Approved public IP or VPN CIDR
from authorized_alb_cidrs
            |
            | HTTPS TCP 443
            | HTTP TCP 80 redirects to HTTPS
            v
Public subnet: 10.0.1.0/24
Application Load Balancer
  - ALB security group checks the source CIDR
  - ACM certificate provides TLS encryption
  - Terminates HTTPS
            |
            | HTTP TCP 8080
            v
Application subnet: 10.0.10.0/24
Application EC2 ASG
  - Accepts traffic only from the ALB security group
  - Allows HTTPS TCP 443 to approved egress CIDRs
      |
      +--> secureweb_egress_cidr
      |
      +--> repository_egress_cidr
            |
            | MySQL TCP 3306
            | Through the application SG -> database SG
            v
Database subnet: 10.0.20.0/24
Database EC2 ASG
  - Accepts MySQL only from the application security group
```

## Before deployment

Update [terraform.tfvars](./terraform.tfvars) with real approved values:

- `authorized_alb_cidrs`: finite public CIDRs that may access the ALB.
- `ssl_certificate_arn`: an ACM certificate ARN for the AWS region.
- `secureweb_egress_cidr`: the approved resolved CIDR for secureweb.com.
- `repository_egress_cidr`: the approved resolved CIDR for repository.example.com.
- `app_instance_type`, `db_instance_type`, and ASG capacity values.

Do not use `0.0.0.0/0` for inbound or external-service egress values.

The external service hostnames must resolve to stable IP ranges before deployment. DNS hostnames should not be used directly in security-group CIDR rules.

## Deploy

```powershell
cd C:\Wrok_Zone\Temp\terraform-task\terraform\environments\dev
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

Always review `terraform plan` before applying changes.

## Quick command reference

```powershell
# Initialize providers and modules
terraform init

# Check formatting and syntax
terraform fmt -check -recursive
terraform validate

# Preview and apply
terraform plan -out=tfplan
terraform apply tfplan

# Show outputs
terraform output

# Cleanup
terraform plan -destroy
terraform destroy
```

## Pre-deployment checklist

- `ssl_certificate_arn` is a valid ACM ARN in the same region.
- `authorized_alb_cidrs` contains only approved finite source CIDRs.
- `secureweb_egress_cidr` and `repository_egress_cidr` are approved resolved CIDRs.
- AWS credentials can create VPC, ALB, EC2, ASG, and security-group resources.
- You reviewed `terraform plan` and confirmed expected changes only.

## Resource-by-resource changes

The following resources are created or configured by [main.tf](./main.tf).

### 1. Common module

**Terraform resource:** `module.common`

**Module:** [terraform/modules/common](../../modules/common)

**Creates:**

- Standardized naming prefixes.
- Environment, owner, project, cost-center, and compliance tags.
- Common security, operations, network, and compliance policy objects.

**Change:**

The module does not create AWS infrastructure directly. It provides consistent policy and naming values to the other modules.

**Dependencies:**

- Uses values from `variables.tf`.
- Must be initialized before modules use its outputs.

**Operational result:**

AWS resources receive consistent tags and names, making ownership and audit reviews easier.

### 2. VPC module

**Terraform resource:** `module.vpc`

**Module:** [terraform/modules/vpc](../../modules/vpc)

**Creates:**

- `aws_vpc.this`: a `10.0.0.0/16` VPC.
- `aws_internet_gateway.this`: public Internet connectivity.
- `aws_subnet.public`: the public ALB subnet.
- `aws_subnet.private`: the application and database subnets.
- Public and private route tables.
- Routes and route-table associations.
- One Elastic IP and NAT gateway.

**Change:**

The public subnet is `10.0.1.0/24`. The private application and database subnets are `10.0.10.0/24` and `10.0.20.0/24`.

The public subnet receives the Internet gateway route. Private subnets use the NAT gateway for approved outbound network access.

**Dependencies:**

- The availability zones and CIDRs come from `terraform.tfvars`.
- The ALB and EC2 modules consume the subnet and VPC IDs from this module.

**Operational result:**

ALB instances can be public, while application and database instances remain in private subnets.

### 3. ALB security group

**Terraform resource:** `aws_security_group.alb`

**Module:** [terraform/modules/security_group](../../modules/security_group)

**Creates:**

- A dedicated security group for the Application Load Balancer.
- HTTPS TCP 443 ingress from every CIDR listed in `authorized_alb_cidrs`.
- TCP 8080 egress to the application security group.

**Change:**

The ALB no longer uses the application security group. Internet access is limited to approved source CIDRs and the HTTPS port.

**Dependencies:**

- Created inside the VPC returned by `module.vpc`.
- Referenced by the load-balancer module.
- Referenced as the source of application ingress traffic.

**Operational result:**

Unauthorized Internet sources cannot reach the ALB. The ALB can communicate with application instances only on port 8080.

### 4. Application security group

**Terraform resource:** `aws_security_group.app`

**Module:** [terraform/modules/security_group](../../modules/security_group)

**Creates:**

- A dedicated security group for application EC2 instances.
- TCP 8080 ingress from the ALB security group.
- TCP/UDP 53 egress to the VPC CIDR for DNS resolution.
- TCP 443 egress to approved secureweb.com and repository.example.com CIDRs.
- TCP 3306 egress to the database security group.

**Change:**

The application tier cannot accept Internet traffic directly. It can initiate only the approved application, database, DNS, and HTTPS flows.

**Dependencies:**

- Uses the ALB security group as the ingress source.
- Uses the database security group as the MySQL egress destination.
- Uses `secureweb_egress_cidr` and `repository_egress_cidr`.
- Attached to the application launch template and ASG instances.

**Operational result:**

Traffic reaches the application only through the ALB. The application can reach MySQL and the two approved external HTTPS destinations.

### 5. Database security group

**Terraform resource:** `aws_security_group.db`

**Module:** [terraform/modules/security_group](../../modules/security_group)

**Creates:**

- A dedicated security group for database EC2 instances.
- TCP 3306 ingress from the application security group.
- No explicit outbound rules.

**Change:**

No external source can reach MySQL directly. AWS security groups do not allow the database tier to initiate outbound traffic unless a matching egress rule exists.

**Dependencies:**

- Uses the application security group as the ingress source.
- Attached to the database launch template and ASG instances.

**Operational result:**

The database tier accepts MySQL traffic only from application instances.

### 6. Application Load Balancer

**Terraform resource:** `aws_lb.this`

**Module:** [terraform/modules/alb_nlb](../../modules/alb_nlb)

**Creates:**

- An internet-facing Application Load Balancer.
- Placement in the public subnet.
- Attachment of the ALB security group.

**Change:**

The load balancer is the only Internet-facing application entry point.

**Dependencies:**

- VPC public subnet ID.
- ALB security group ID.
- AWS certificate ARN for the HTTPS listener.

**Operational result:**

Internet traffic enters through the ALB instead of directly reaching EC2 instances.

### 7. ALB target group

**Terraform resource:** `aws_lb_target_group.this`

**Module:** [terraform/modules/alb_nlb](../../modules/alb_nlb)

**Creates:**

- A target group named from `naming_prefix`.
- HTTP targets on TCP port 8080.
- A health check for `/`.
- Instance-target type.

**Change:**

The ALB forwards decrypted HTTPS traffic to application instances over HTTP on port 8080.

**Dependencies:**

- VPC ID.
- Application Auto Scaling Group registration.

**Operational result:**

The ALB checks application health and sends traffic only to healthy targets.

### 8. HTTPS listener

**Terraform resource:** `aws_lb_listener.https`

**Module:** [terraform/modules/alb_nlb](../../modules/alb_nlb)

**Creates:**

- TCP 443 listener.
- HTTPS protocol.
- TLS 1.2/1.3 security policy.
- ACM certificate attachment.
- Forwarding action to the application target group.

**Change:**

External clients now use a valid HTTPS listener instead of unencrypted ALB traffic.

**Dependencies:**

- Load balancer ARN.
- ACM certificate ARN.
- Target-group ARN.

**Operational result:**

TLS terminates at the ALB. Traffic between the ALB and application instances uses port 8080.

### 9. HTTP redirect listener

**Terraform resource:** `aws_lb_listener.http_redirect`

**Module:** [terraform/modules/alb_nlb](../../modules/alb_nlb)

**Creates:**

- TCP 80 listener.
- HTTP 301 redirect to HTTPS TCP 443.

**Change:**

HTTP requests no longer need to be served directly.

**Dependencies:**

- The load balancer and HTTPS listener certificate configuration.

**Operational result:**

All application access is redirected to HTTPS.

### 10. Application launch template

**Terraform resource:** `aws_launch_template.this`

**Module:** [terraform/modules/ec2_asg](../../modules/ec2_asg)

**Creates:**

- Amazon Linux 2 launch configuration.
- Selected EC2 instance type.
- Application security group attachment.
- Base64-encoded application startup script.
- Instance name and module tags.

**Change:**

The application package installation and service startup are now part of infrastructure configuration.

**Dependencies:**

- Application AMI.
- Application instance type.
- Application security group ID.
- `app_user_data`.

**Operational result:**

New application instances receive the same package installation and startup process automatically.

### 11. Application Auto Scaling Group

**Terraform resource:** `aws_autoscaling_group.this`

**Module:** [terraform/modules/ec2_asg](../../modules/ec2_asg)

**Creates:**

- Application ASG.
- Placement in the private application subnet.
- Min, max, and desired capacity of 1 by default.
- Registration with the application target group.

**Change:**

The application uses the ASG launch template while remaining private. The ASG is attached to the ALB target group.

**Dependencies:**

- Application launch template.
- Application subnet ID.
- Application target-group ARN.

**Operational result:**

The ALB registers application instances and removes unhealthy instances from service.

### 12. Database launch template

**Terraform resource:** `aws_launch_template.this`

**Module:** [terraform/modules/ec2_asg](../../modules/ec2_asg)

**Creates:**

- Amazon Linux 2 launch configuration.
- Database instance type.
- Database security group attachment.
- Base64-encoded database startup script.

**Change:**

The database instance uses Infrastructure as Code and is placed in the private database subnet.

**Dependencies:**

- Database AMI.
- Database instance type.
- Database security group ID.
- `db_user_data`.

**Operational result:**

New database instances receive the configured MySQL startup behavior automatically.

### 13. Database Auto Scaling Group

**Terraform resource:** `aws_autoscaling_group.this`

**Module:** [terraform/modules/ec2_asg](../../modules/ec2_asg)

**Creates:**

- A single-instance compatibility ASG.
- Placement in the private database subnet.
- Min, max, and desired capacity of 1.
- No ALB target-group registration.

**Change:**

The database remains private and is not load-balanced or exposed to the Internet.

**Dependencies:**

- Database launch template.
- Database subnet ID.
- Database security group.

**Operational result:**

The database is reachable only on TCP 3306 from application instances.

### 14. Amazon Linux AMI lookup

**Terraform data source:** `data.aws_ami.amazon_linux_2`

**Creates:**

- No AWS infrastructure.
- Resolves the latest Amazon Linux 2 AMI when an explicit AMI ID is not configured.

**Change:**

Both EC2 launch templates use the resolved AMI unless `app_ami_id` or `db_ami_id` is explicitly set.

**Dependencies:**

- AWS region.
- Amazon AMI publisher.

**Operational result:**

The environment uses a current Amazon Linux 2 AMI while still allowing pinned AMI overrides.

## Security behavior

| Flow | Source | Destination | Port | Result |
|---|---|---|---|---|
| Internet to ALB | `authorized_alb_cidrs` | ALB SG | TCP 443 | Allowed |
| Internet HTTP to ALB | Internet source | ALB SG | TCP 80 | Redirected to HTTPS |
| ALB to app | ALB SG | App SG | TCP 8080 | Allowed |
| App to database | App SG | Database SG | TCP 3306 | Allowed |
| App to package repository | App SG | `repository_egress_cidr` | TCP 443 | Allowed |
| App to secureweb | App SG | `secureweb_egress_cidr` | TCP 443 | Allowed |
| App DNS | App SG | VPC resolver CIDR | TCP/UDP 53 | Allowed |
| Database outbound | Database SG | Any | Any | Not explicitly allowed |

## Outputs

[outputs.tf](./outputs.tf) publishes resource IDs, load-balancer details, ASG names, and a PCI-DSS summary.

Important outputs:

- `vpc_id`: VPC ID.
- `public_subnet_id`: public ALB subnet.
- `app_subnet_id`: private application subnet.
- `database_subnet_id`: private database subnet.
- `alb_dns_name`, `alb_arn`, and `alb_zone_id`: load-balancer details.
- `alb_security_group_id`, `app_security_group_id`, and `database_security_group_id`: security-group IDs.
- `app_asg_name` and `db_asg_name`: Auto Scaling Group names.
- `pci_compliance_summary`: network and access-control summary.
- `application_url`: HTTPS application URL.

## Importing existing resources

If this environment should manage already-existing AWS resources, use [TERRAFORM_IMPORT_GUIDE.md](./TERRAFORM_IMPORT_GUIDE.md).

High-level flow:

1. Match `terraform.tfvars` to real AWS values (CIDRs, names, sizes, IDs).
2. Run `terraform init`.
3. Import each resource into the matching module address.
4. Run `terraform plan` repeatedly until the plan is stable and expected.

## Cleanup

```powershell
terraform plan -destroy
terraform destroy
```
