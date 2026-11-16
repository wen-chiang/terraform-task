terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment after first run to enable remote state
  # backend "s3" {
  #   bucket         = "terraform-state-pci-dss"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  # Allow terraform validate/plan without real AWS credentials
  # These flags skip validation checks for local testing
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "pci-dss-compliance"
      Terraform   = "true"
      CreatedDate = timestamp()
    }
  }
}
