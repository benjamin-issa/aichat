terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket = "bissa-aichat-tfstate"
    key    = "librechat/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Obtain information about the current AWS account & default VPC

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # Only subnets that auto-assign public IPs are considered "public" in the default VPC
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
} 