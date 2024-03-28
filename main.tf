terraform {
  required_version = "v1.0.1"
  required_providers {
    aws = "5.42.0"
  }
  backend "local" {}
}

module "aws_crm" {
  source = "./module/crm/aws"
  environment = var.environment
  ssh_public_key = var.ssh_public_key
  s3_bucket_prefix = var.aws_s3_bucket_prefix
  ec2_ami_id = var.aws_ec2_ami_id
}
