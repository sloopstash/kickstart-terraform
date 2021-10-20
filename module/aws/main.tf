provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = "tuto"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "iam_ec2_rl" {
  depends_on = [
    aws_s3_bucket.s3_app_stt_bkt
  ]
  name = "${var.env}-iam-ec2-rl"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  path = "/"
  tags = {
    Name = "${var.env}-iam-ec2-rl"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_iam_role_policy_attachment" "iam_ec2_rl_plcy_1" {
  depends_on = [aws_iam_role.iam_ec2_rl]
  role = aws_iam_role.iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_instance_profile" "iam_ec2_rl_inst_pf" {
  depends_on = [aws_iam_role.iam_ec2_rl]
  role = aws_iam_role.iam_ec2_rl.name
  path = "/"
  tags = {
    Name = "${var.env}-iam-ec2-rl-inst-pf"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_vpc" "vpc_net" {
  cidr_block = var.env == "prd" ? "11.1.0.0/16" : "12.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  enable_classiclink = false
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "${var.env}-vpc-net"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_internet_gateway" "vpc_ig" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  tags = {
    Name = "${var.env}-vpc-ig"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table" "vpc_pub_rtt" {
  depends_on = [
    aws_vpc.vpc_net,
    aws_internet_gateway.vpc_ig
  ]
  vpc_id = aws_vpc.vpc_net.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_ig.id
  }
  tags = {
    Name = "${var.env}-vpc-pub-rtt"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table" "vpc_pvt_rtt" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  tags = {
    Name = "${var.env}-vpc-pvt-rtt"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_vpc_endpoint" "vpc_s3_ep" {
  depends_on = [
    aws_vpc.vpc_net,
    aws_route_table.vpc_pub_rtt,
    aws_route_table.vpc_pvt_rtt
  ]
  vpc_id = aws_vpc.vpc_net.id
  service_name = join(".",["com.amazonaws",data.aws_region.current.name,"s3"])
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.vpc_pub_rtt.id,
    aws_route_table.vpc_pvt_rtt.id
  ]
  tags = {
    Name = "${var.env}-vpc-s3-ep"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
