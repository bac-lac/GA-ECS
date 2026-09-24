terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }
  }

  backend "s3" {
    bucket        = "main-tfstate-c71307a3"
    region        = "ca-central-1"
    encrypt       = true
    use_lockfile  = true
  }
}

provider "aws" {
  region  = "ca-central-1"
  assume_role {
    role_arn    = "${var.ROLE_ARN}"
    external_id = "${var.EXTERNAL_ID}"
  }
}