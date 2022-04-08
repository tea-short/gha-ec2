data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "current" {}

provider "aws" {
  region = "eu-west-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }
  }
  required_version = ">= 1.1.7"

  backend "s3" {
    bucket = "bootstrap-tfstate-ac1db8b1"
    key    = "gha-ec2.tfstate"
    region = "eu-west-2"

  }
}

