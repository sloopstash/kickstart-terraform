terraform {
  required_version = "0.12.18"
  required_providers {
    aws = "2.60.0"
  }
  backend "local" {
    path = "stg-base-tfm-cfg.tfstate"
  }
}

provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = "tuto"
}

variable "env" {
  type = string
}
variable "stg_vpc_cidr_blk" {
  type = string
}
variable "stg_s3_stt_bkt_pfx" {
  type = string
}
variable "vpc_sn_conf" {
  type = map
  default = {
    "app_sn_1" = { "az" = "us-west-2a", "cidr" = "10.2.1.0/24" }
    "app_sn_2" = { "az" = "us-west-2b", "cidr" = "10.2.2.0/24" }
    "redis_sn_1" = { "az" = "us-west-2a", "cidr" = "10.2.3.0/24" }
    "redis_sn_2" = { "az" = "us-west-2b", "cidr" = "10.2.4.0/24" }
    "nat_sn_1" = { "az" = "us-west-2a", "cidr" = "10.2.5.0/24" }
    "nat_sn_2" = { "az" = "us-west-2b", "cidr" = "10.2.6.0/24" }
    "lb_sn_1" = { "az" = "us-west-2a", "cidr" = "10.2.7.0/24" }
    "lb_sn_2" = { "az" = "us-west-2b", "cidr" = "10.2.8.0/24" }
  }
}

resource "aws_vpc" "stg_vpc" {
  # count = var.env == "STG" ? 1 : 0
  cidr_block = var.stg_vpc_cidr_blk
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name = "STG-VPC"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_internet_gateway" "stg_vpc_ig" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  tags = {
    Name = "STG-VPC-IG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table" "stg_vpc_rtt_pub" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_internet_gateway.stg_vpc_ig]
  vpc_id = aws_vpc.stg_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stg_vpc_ig.id
  }
  tags = {
    Name = "STG-VPC-RTT-PUB"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table" "stg_vpc_rtt_pvt" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  tags = {
    Name = "STG-VPC-RTT-PVT"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_subnet" "stg_vpc_app_sn_1" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["app_sn_1"]["cidr"]
  availability_zone = var.vpc_sn_conf["app_sn_1"]["az"]
  tags = {
    Name = "STG-VPC-App-SN-1"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_app_sn_1_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_app_sn_1, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_app_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_app_sn_2" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["app_sn_2"]["cidr"]
  availability_zone = var.vpc_sn_conf["app_sn_2"]["az"]
  tags = {
    Name = "STG-VPC-App-SN-2"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_app_sn_2_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_app_sn_2, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_app_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_redis_sn_1" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["redis_sn_1"]["cidr"]
  availability_zone = var.vpc_sn_conf["redis_sn_1"]["az"]
  tags = {
    Name = "STG-VPC-Redis-SN-1"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_redis_sn_1_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_redis_sn_1, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_redis_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_redis_sn_2" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["redis_sn_2"]["cidr"]
  availability_zone = var.vpc_sn_conf["redis_sn_2"]["az"]
  tags = {
    Name = "STG-VPC-Redis-SN-2"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_redis_sn_2_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_redis_sn_2, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_redis_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_nat_sn_1" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["nat_sn_1"]["cidr"]
  availability_zone = var.vpc_sn_conf["nat_sn_1"]["az"]
  tags = {
    Name = "STG-VPC-NAT-SN-1"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_nat_sn_1_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_nat_sn_1, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_nat_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_nat_sn_2" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["nat_sn_2"]["cidr"]
  availability_zone = var.vpc_sn_conf["nat_sn_2"]["az"]
  tags = {
    Name = "STG-VPC-NAT-SN-2"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_nat_sn_2_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_nat_sn_2, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_nat_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_lb_sn_1" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["lb_sn_1"]["cidr"]
  availability_zone = var.vpc_sn_conf["lb_sn_1"]["az"]
  tags = {
    Name = "STG-VPC-LB-SN-1"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_lb_sn_1_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_lb_sn_1, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_lb_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_lb_sn_2" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  cidr_block = var.vpc_sn_conf["lb_sn_2"]["cidr"]
  availability_zone = var.vpc_sn_conf["lb_sn_2"]["az"]
  tags = {
    Name = "STG-VPC-LB-SN-2"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_route_table_association" "stg_vpc_lb_sn_2_rtt_ass" {
  # count = var.env == "STG" ? 1 : 0
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_lb_sn_2, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_lb_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_s3_bucket" "stg_s3_stt_bkt" {
  bucket = join("-", [var.stg_s3_stt_bkt_pfx, "stg-s3-stt-bkt"])
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name = "STG-S3-STT-BKT"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}

output "stg_vpc_id" {
  depends_on = [aws_vpc.stg_vpc]
  value = aws_vpc.stg_vpc.id
}
