terraform {
  required_version = ">= 1.3.5"    
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.41"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}