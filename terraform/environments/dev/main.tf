# Common Module - Foundation
module "common" {
  source = "../../modules/common"

  company_code          = var.company_code
  environment           = var.environment
  region                = var.aws_region
  owner                 = var.owner
  cost_center           = var.cost_center
  project               = var.project
  company_name          = var.company_name
  compliance_framework  = "PCI-DSS"
  mode                  = "strict"
  additional_tags       = var.tags
}

# VPC Module - Network Foundation
module "vpc" {
  source = "../../modules/vpc"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  cidr_block               = var.vpc_cidr
  azs                      = var.availability_zones
  public_subnet_cidrs      = [var.public_subnet_cidr]
  private_subnet_cidrs     = [var.app_subnet_cidr, var.db_subnet_cidr]
  enable_internet_gateway  = true
  enable_nat_gateway       = true
  single_nat_gateway       = true
}

# Security Groups Module - PCI-DSS 1.3.1 & 1.3.2 Compliance
# Implements network segmentation and access control
module "security_groups" {
  source = "../../modules/security_group"

  naming_prefix = var.naming_prefix
  tags          = var.tags
  vpc_id        = module.vpc.vpc_id

  # ALB Security Group - Restricted inbound from authorized IPs
  app_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = var.public_subnet_cidr
      description = "HTTP from ALB subnet (internal)"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = var.public_subnet_cidr
      description = "HTTPS from ALB subnet (restricted access)"
    }
  ]

  # Database security group port
  db_port = 3306
}

# Application Load Balancer Module
module "load_balancer" {
  source = "../../modules/alb_nlb"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  module_settings = {
    load_balancer_type = "application"
    internal           = var.alb_internal
    name               = "${var.naming_prefix}-alb"
    security_group_ids = [module.security_groups.app_sg_id]
    subnet_ids         = [module.vpc.public_subnet_ids[0]]
    vpc_id             = module.vpc.vpc_id

    target_groups = [
      {
        name        = "${var.naming_prefix}-tg"
        port        = 8080
        protocol    = "HTTP"
        target_type = "instance"

        health_check = {
          healthy_threshold   = 2
          unhealthy_threshold = 2
          timeout             = 5
          interval            = 30
          path                = "/"
          matcher             = "200"
        }
      }
    ]
  }
}

# Application Server EC2 with Auto Scaling Group
module "app_server" {
  source = "../../modules/ec2_asg"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  module_settings = {
    # Auto Scaling Configuration (Min 1, Max 1 for POC = single instance)
    min_size             = var.asg_min_size
    max_size             = var.asg_max_size
    desired_capacity     = var.asg_desired_capacity

    # Instance Configuration
    instance_type        = var.app_instance_type
    image_id             = var.app_ami_id != "" ? var.app_ami_id : data.aws_ami.amazon_linux_2.id
    security_group_ids   = [module.security_groups.app_sg_id]
    subnet_ids           = [module.vpc.private_subnet_ids[0]]

    # Naming
    name                 = "${var.naming_prefix}-app-asg"

    # Target Group
    target_group_arn     = module.load_balancer.target_group_arns[0]

    # User Data
    user_data            = base64encode(var.app_user_data)
  }
}

# Database Server EC2 Instance
# Note: This creates a database on EC2 (not RDS) as per task requirements
module "database_server" {
  source = "../../modules/ec2_asg"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  module_settings = {
    # Single instance (no scaling)
    min_size             = 1
    max_size             = 1
    desired_capacity     = 1

    # Instance Configuration
    instance_type        = var.db_instance_type
    image_id             = var.db_ami_id != "" ? var.db_ami_id : data.aws_ami.amazon_linux_2.id
    security_group_ids   = [module.security_groups.db_sg_id]
    subnet_ids           = [module.vpc.private_subnet_ids[1]]

    # Naming
    name                 = "${var.naming_prefix}-db-asg"

    # No target group for database
    target_group_arn     = ""

    # User Data
    user_data            = base64encode(var.db_user_data)
  }
}

# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
