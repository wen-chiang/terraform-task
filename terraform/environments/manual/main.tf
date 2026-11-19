# Common Module - Foundation
module "common" {
  source = "../../modules/common"

  company_code         = var.company_code
  environment          = var.environment
  region               = var.aws_region
  owner                = var.owner
  cost_center          = var.cost_center
  project              = var.project
  company_name         = var.company_name
  compliance_framework = "PCI-DSS"
  mode                 = "strict"
  additional_tags      = var.tags
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

# Security Groups Module - Audit fast-track controls
module "security_groups" {
  source = "../../modules/security_group"

  naming_prefix = var.naming_prefix
  tags          = var.tags
  vpc_id        = module.vpc.vpc_id

  app_ingress_rules = flatten([
    for cidr in var.authorized_alb_cidrs : [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = cidr
        description = "HTTP from authorized sources"
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = cidr
        description = "HTTPS from authorized sources"
      }
    ]
  ])

  app_egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = var.repository_egress_cidr
      description = "HTTPS to repository.example.com"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = var.secureweb_egress_cidr
      description = "HTTPS to secureweb.com"
    }
  ]

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

    target_groups = {
      app = {
        name              = "${var.naming_prefix}-tg"
        port              = 8080
        protocol          = "HTTP"
        health_check_path = "/"
      }
    }
  }
}

# Application Server (single-instance ASG for compatibility)
module "app_server" {
  source = "../../modules/ec2_asg"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  module_settings = {
    min_size           = var.asg_min_size
    max_size           = var.asg_max_size
    desired_capacity   = var.asg_desired_capacity
    instance_type      = var.app_instance_type
    image_id           = var.app_ami_id != "" ? var.app_ami_id : data.aws_ami.amazon_linux_2.id
    security_group_ids = [module.security_groups.app_sg_id]
    subnet_ids         = [module.vpc.private_subnet_ids[0]]
    name               = "${var.naming_prefix}-app-asg"
  }
}

# Database Server (single-instance ASG for compatibility)
module "database_server" {
  source = "../../modules/ec2_asg"

  naming_prefix = var.naming_prefix
  tags          = var.tags

  module_settings = {
    min_size           = 1
    max_size           = 1
    desired_capacity   = 1
    instance_type      = var.db_instance_type
    image_id           = var.db_ami_id != "" ? var.db_ami_id : data.aws_ami.amazon_linux_2.id
    security_group_ids = [module.security_groups.db_sg_id]
    subnet_ids         = [module.vpc.private_subnet_ids[1]]
    name               = "${var.naming_prefix}-db-asg"
  }
}

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
