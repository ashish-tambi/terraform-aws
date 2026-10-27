
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "hyderabad"
  region = "ap-south-2"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_caller_identity" "mumbai" {}

data "aws_caller_identity" "hyderabad" {
  provider = aws.hyderabad
}

data "aws_caller_identity" "virginia" {
  provider = aws.virginia
}

output "account_and_regions" {
  value = {
    mumbai    = data.aws_caller_identity.mumbai.account_id
    hyderabad = data.aws_caller_identity.hyderabad.account_id
    virginia  = data.aws_caller_identity.virginia.account_id
  }
}

