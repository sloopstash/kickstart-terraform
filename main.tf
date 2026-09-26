terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.65.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.6.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "8.3.0"
    }
  }
  backend "local" {}
}

module "base_aws" {
  source = "./module/base/aws"
  environment = var.environment
  ssh_public_key = var.ssh_public_key
  s3_bucket_prefix = var.aws_s3_bucket_prefix
  ec2_ami_id = var.aws_ec2_ami_id
}
module "base_azure" {
  source = "./module/base/azure"
  environment = var.environment
  ssh_public_key = var.ssh_public_key
  subscription_id = var.azure_subscription_id
}
module "docker_aws" {
  source = "./module/docker/aws"
  environment = var.environment
  vpc_net_id = module.base_aws.vpc_net_id
  vpc_pvt_rtt_id = module.base_aws.vpc_pvt_rtt_id
  vpc_bastion_sg_id = module.base_aws.vpc_bastion_sg_id
  vpc_loadbalancer_sg_id = module.base_aws.vpc_loadbalancer_sg_id
}
module "docker_azure" {
  source = "./module/docker/azure"
  environment = var.environment
  subscription_id = var.azure_subscription_id
  rg_name = module.base_azure.rg_name
  rg_location = module.base_azure.rg_location
  vnet_name = module.base_azure.vnet_name
  ng_id = module.base_azure.ng_id
}
module "kubernetes_aws" {
  source = "./module/kubernetes/aws"
  environment = var.environment
  iam_ec2_rl_arn = module.base_aws.iam_ec2_rl_arn
  vpc_net_id = module.base_aws.vpc_net_id
  vpc_loadbalancer_sn_1_id = module.base_aws.vpc_loadbalancer_sn_1_id
  vpc_loadbalancer_sn_2_id = module.base_aws.vpc_loadbalancer_sn_2_id
  vpc_pvt_rtt_id = module.base_aws.vpc_pvt_rtt_id
  vpc_bastion_sg_id = module.base_aws.vpc_bastion_sg_id
  vpc_loadbalancer_sg_id = module.base_aws.vpc_loadbalancer_sg_id
  ec2_rsa_kp_id = module.base_aws.ec2_rsa_kp_id
}
module "kubernetes_azure" {
  source = "./module/kubernetes/azure"
  environment = var.environment
  subscription_id = var.azure_subscription_id
  rg_name = module.base_azure.rg_name
  rg_location = module.base_azure.rg_location
  vnet_name = module.base_azure.vnet_name
  ng_id = module.base_azure.ng_id
}
