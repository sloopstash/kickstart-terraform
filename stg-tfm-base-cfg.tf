terraform {
  required_version = "v0.14.4"
  required_providers {
    aws = "3.23.0"
  }
  backend "local" {
    path = "stg-tfm-base-cfg.tfstate"
  }
}

provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = "tuto"
}

variable "env" {
  type = string
  description = "CRM Environment."
}
variable "stg_vpc_cidr_blk" {
  type = string
  description = "STG VPC CIDR Block."
}
variable "stg_s3_stt_bkt_pfx" {
  type = string
  description = "STG S3 Static Bucket Prefix."
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

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "stg_iam_ec2_rl" {
  # count = var.env == "STG" ? 1 : 0
  name = "STG-IAM-EC2-RL"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  path = "/"
  tags = {
    Name = "STG-IAM-EC2-RL"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_iam_role_policy_attachment" "stg_iam_ec2_rl_plcy_1" {
  role = aws_iam_role.stg_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_vpc" "stg_vpc" {
  cidr_block = var.stg_vpc_cidr_blk
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "STG-VPC"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_internet_gateway" "stg_vpc_ig" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_app_sn_1, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_app_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_app_sn_2" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_app_sn_2, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_app_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_redis_sn_1" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_redis_sn_1, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_redis_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_redis_sn_2" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_redis_sn_2, aws_route_table.stg_vpc_rtt_pvt]
  subnet_id = aws_subnet.stg_vpc_redis_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pvt.id
}
resource "aws_subnet" "stg_vpc_nat_sn_1" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_nat_sn_1, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_nat_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_nat_sn_2" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_nat_sn_2, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_nat_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_lb_sn_1" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_lb_sn_1, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_lb_sn_1.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_subnet" "stg_vpc_lb_sn_2" {
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
  depends_on = [aws_vpc.stg_vpc, aws_subnet.stg_vpc_lb_sn_2, aws_route_table.stg_vpc_rtt_pub]
  subnet_id = aws_subnet.stg_vpc_lb_sn_2.id
  route_table_id = aws_route_table.stg_vpc_rtt_pub.id
}
resource "aws_security_group" "stg_vpc_nat_sg" {
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  name = "STG-VPC-NAT-SG"
  description = "STG VPC NAT Security Group."
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [aws_vpc.stg_vpc.cidr_block]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "STG-VPC-NAT-SG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_security_group" "stg_vpc_lb_sg" {
  depends_on = [aws_vpc.stg_vpc]
  vpc_id = aws_vpc.stg_vpc.id
  name = "STG-VPC-LB-SG"
  description = "STG VPC LB Security Group."
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "STG-VPC-LB-SG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_security_group" "stg_vpc_app_sg" {
  depends_on = [aws_vpc.stg_vpc, aws_security_group.stg_vpc_nat_sg, aws_security_group.stg_vpc_lb_sg]
  vpc_id = aws_vpc.stg_vpc.id
  name = "STG-VPC-App-SG"
  description = "STG VPC App Security Group."
  ingress {
    protocol = "tcp"
    from_port = 5000
    to_port = 5000
    security_groups = [aws_security_group.stg_vpc_lb_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.stg_vpc_nat_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "STG-VPC-App-SG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_security_group" "stg_vpc_redis_sg" {
  depends_on = [aws_vpc.stg_vpc, aws_security_group.stg_vpc_nat_sg, aws_security_group.stg_vpc_app_sg]
  vpc_id = aws_vpc.stg_vpc.id
  name = "STG-VPC-Redis-SG"
  description = "STG VPC Redis Security Group."
  ingress {
    protocol = "tcp"
    from_port = 6379
    to_port = 6379
    security_groups = [aws_security_group.stg_vpc_app_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.stg_vpc_nat_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "STG-VPC-Redis-SG"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_vpc_endpoint" "stg_vpc_s3_ep" {
  depends_on = [aws_vpc.stg_vpc, aws_route_table.stg_vpc_rtt_pvt]
  vpc_id = aws_vpc.stg_vpc.id
  service_name = join("", ["com.amazonaws.", data.aws_region.current.name, ".s3"])
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.stg_vpc_rtt_pvt.id]
}
resource "aws_s3_bucket" "stg_s3_stt_bkt" {
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  bucket = join("-", [var.stg_s3_stt_bkt_pfx, "stg-s3-stt-bkt"])
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = []
    max_age_seconds = 86400
  }
  tags = {
    Name = "STG-S3-STT-BKT"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}
resource "aws_s3_access_point" "stg_s3_stt_vpc_acss_pt" {
  bucket = aws_s3_bucket.stg_s3_stt_bkt.arn
  name = "stg-s3-stt-vpc-acss-pt"
  public_access_block_configuration {
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
  }
  vpc_configuration {
    vpc_id = aws_vpc.stg_vpc.id
  }
}
resource "aws_s3_access_point" "stg_s3_stt_int_acss_pt" {
  bucket = aws_s3_bucket.stg_s3_stt_bkt.arn
  name = "stg-s3-stt-int-acss-pt"
  policy = <<POLICY
{
  "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "001",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/tuto"
        },
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
            "arn:aws:s3:us-west-2:${data.aws_caller_identity.current.account_id}:accesspoint/stg-s3-stt-int-acss-pt",
            "arn:aws:s3:us-west-2:${data.aws_caller_identity.current.account_id}:accesspoint/stg-s3-stt-int-acss-pt/object/*"
        ]
        }
    ]
}
POLICY
  public_access_block_configuration {
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
  }
}
resource "aws_cloudfront_origin_access_identity" "stg_cf_stt_oai" {
  comment = "STG CloudFront Static Origin Access Identity."
}
resource "aws_s3_bucket_policy" "stg_s3_stt_bkt_plcy" {
  depends_on = [aws_s3_bucket.stg_s3_stt_bkt, aws_cloudfront_origin_access_identity.stg_cf_stt_oai]
  bucket = aws_s3_bucket.stg_s3_stt_bkt.id
  policy = <<POLICY
{
  "Statement": [
    {
      "Sid": "001",
      "Effect": "Allow",
      "Principal": {
        "CanonicalUser": "${aws_cloudfront_origin_access_identity.stg_cf_stt_oai.s3_canonical_user_id}"
      },
      "Action": ["s3:GetObject"],
      "Resource": "${join("", ["arn:aws:s3:::", join("-", [var.stg_s3_stt_bkt_pfx, "stg-s3-stt-bkt"]), "/*"])}"
    }
  ]
}
POLICY
}
resource "aws_cloudfront_distribution" "stg_cf_stt_dst" {
  depends_on = [aws_s3_bucket.stg_s3_stt_bkt, aws_cloudfront_origin_access_identity.stg_cf_stt_oai, aws_s3_bucket_policy.stg_s3_stt_bkt_plcy]
  comment = "STG CloudFront Static Distribution."
  origin {
    domain_name = aws_s3_bucket.stg_s3_stt_bkt.bucket_regional_domain_name
    origin_id = "S3-${aws_s3_bucket.stg_s3_stt_bkt.id}"
    s3_origin_config {
      origin_access_identity = join("/", ["origin-access-identity", "cloudfront", aws_cloudfront_origin_access_identity.stg_cf_stt_oai.id])
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    compress = false
    default_ttl = 86400
    min_ttl = 0
    max_ttl = 31536000
    smooth_streaming = false
    target_origin_id = "S3Origin"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  enabled = true
  http_version = "http2"
  is_ipv6_enabled = false
  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  wait_for_deployment = false
  tags = {
    Name = "STG-CF-STT-DST"
    Environment = "STG"
    Region = "us-west-2"
    Product = "CRM"
  }
}

output "stg_vpc_id" {
  depends_on = [aws_vpc.stg_vpc]
  value = aws_vpc.stg_vpc.id
}

output "stg_cf_stt_dst_url" {
  depends_on = [aws_cloudfront_distribution.stg_cf_stt_dst]
  value = aws_cloudfront_distribution.stg_cf_stt_dst.domain_name
}
