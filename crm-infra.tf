terraform {
  required_version = ">=0.12.18"
  required_providers {
    aws = ">= 2.43.0"
  }
  backend "local" {
    path = "crm-infra.tfstate"
  }
}

provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = "tuto"
}

resource "aws_vpc" "crm_stg_vpc" {
  cidr_block = "20.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "CRM-STG-VPC"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}

resource "aws_internet_gateway" "crm_stg_ig" {
  depends_on = [aws_vpc.crm_stg_vpc]
  vpc_id = aws_vpc.crm_stg_vpc.id
  tags = {
    Name = "CRM-STG-IG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}

resource "aws_s3_bucket" "crm_stg_stt_bkt" {
  bucket = "crm-stg-stt-bkt"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name = "CRM-STG-STT-BKT"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}

output "crm_stg_vpc" {
  depends_on = [aws_vpc.crm_stg_vpc]
  value = aws_vpc.crm_stg_vpc.id
}
