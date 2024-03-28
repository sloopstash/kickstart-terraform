provider "aws" {
  region = "ap-south-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "tuto"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "crm_iam_ec2_rl" {
  name = "crm-iam-ec2-rl"
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
    Name = "crm-iam-ec2-rl"
    Environment = var.environment
    Stack = "crm"
    Organization = "sloopstash"
  }
}
resource "aws_iam_role_policy_attachment" "crm_iam_ec2_rl_plcy_1" {
  depends_on = [aws_iam_role.crm_iam_ec2_rl]
  role = aws_iam_role.crm_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "crm_iam_ec2_rl_plcy_2" {
  depends_on = [aws_iam_role.crm_iam_ec2_rl]
  role = aws_iam_role.crm_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "crm_iam_ec2_rl_plcy_3" {
  depends_on = [aws_iam_role.crm_iam_ec2_rl]
  role = aws_iam_role.crm_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "crm_iam_ec2_rl_plcy_4" {
  depends_on = [aws_iam_role.crm_iam_ec2_rl]
  role = aws_iam_role.crm_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_instance_profile" "crm_iam_ec2_rl_inst_pf" {
  depends_on = [aws_iam_role.crm_iam_ec2_rl]
  role = aws_iam_role.crm_iam_ec2_rl.name
  path = "/"
  tags = {
    Name = "crm-iam-ec2-rl-inst-pf"
    Environment = var.environment
    Stack = "crm"
    Organization = "sloopstash"
  }
}
resource "aws_vpc" "crm_vpc_net" {
  cidr_block = var.environment == "prd" ? "11.1.0.0/16" : "12.1.0.0/16"
  assign_generated_ipv6_cidr_block = false
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name = "crm-vpc-net"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_internet_gateway" "crm_vpc_ig" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  tags = {
    Name = "crm-vpc-ig"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table" "crm_vpc_pub_rtt" {
  depends_on = [
    aws_vpc.crm_vpc_net,
    aws_internet_gateway.crm_vpc_ig
  ]
  vpc_id = aws_vpc.crm_vpc_net.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.crm_vpc_ig.id
  }
  tags = {
    Name = "crm-vpc-pub-rtt"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table" "crm_vpc_pvt_rtt" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  tags = {
    Name = "crm-vpc-pvt-rtt"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_subnet" "crm_vpc_redis_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.1.0/24" : "12.1.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-redis-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_redis_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_redis_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_redis_sn_1.id
}
resource "aws_subnet" "crm_vpc_redis_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.2.0/24" : "12.1.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-redis-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_redis_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_redis_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_redis_sn_2.id
}
resource "aws_subnet" "crm_vpc_app_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.3.0/24" : "12.1.3.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-app-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_app_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_app_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_app_sn_1.id
}
resource "aws_subnet" "crm_vpc_app_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.4.0/24" : "12.1.4.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-app-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_app_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_app_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_app_sn_2.id
}
resource "aws_subnet" "crm_vpc_nginx_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.5.0/24" : "12.1.5.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-nginx-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_nginx_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_nginx_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_nginx_sn_1.id
}
resource "aws_subnet" "crm_vpc_nginx_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.6.0/24" : "12.1.6.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-nginx-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_nginx_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pvt_rtt,
    aws_subnet.crm_vpc_nginx_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pvt_rtt.id
  subnet_id = aws_subnet.crm_vpc_nginx_sn_2.id
}
resource "aws_subnet" "crm_vpc_bastion_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.7.0/24" : "12.1.7.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-bastion-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_bastion_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_bastion_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_bastion_sn_1.id
}
resource "aws_subnet" "crm_vpc_bastion_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.8.0/24" : "12.1.8.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-bastion-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_bastion_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_bastion_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_bastion_sn_2.id
}
resource "aws_subnet" "crm_vpc_nat_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.9.0/24" : "12.1.9.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-nat-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_nat_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_nat_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_nat_sn_1.id
}
resource "aws_subnet" "crm_vpc_nat_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.10.0/24" : "12.1.10.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-nat-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_nat_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_nat_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_nat_sn_2.id
}
resource "aws_subnet" "crm_vpc_loadbalancer_sn_1" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.11.0/24" : "12.1.11.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "crm-vpc-loadbalancer-sn-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_loadbalancer_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_loadbalancer_sn_1
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_loadbalancer_sn_1.id
}
resource "aws_subnet" "crm_vpc_loadbalancer_sn_2" {
  depends_on = [aws_vpc.crm_vpc_net]
  vpc_id = aws_vpc.crm_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.1.12.0/24" : "12.1.12.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "crm-vpc-loadbalancer-sn-2"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "crm_vpc_loadbalancer_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.crm_vpc_pub_rtt,
    aws_subnet.crm_vpc_loadbalancer_sn_2
  ]
  route_table_id = aws_route_table.crm_vpc_pub_rtt.id
  subnet_id = aws_subnet.crm_vpc_loadbalancer_sn_2.id
}
resource "aws_security_group" "crm_vpc_redis_sg" {
  depends_on = [
    aws_vpc.crm_vpc_net,
    aws_security_group.crm_vpc_app_sg,
    aws_security_group.crm_vpc_bastion_sg
  ]
  name = "crm-vpc-redis-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
  ingress {
    protocol = "tcp"
    from_port = 3000
    to_port = 3000
    security_groups = [aws_security_group.crm_vpc_app_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.crm_vpc_bastion_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crm-vpc-redis-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "crm_vpc_app_sg" {
  depends_on = [
    aws_vpc.crm_vpc_net,
    aws_security_group.crm_vpc_nginx_sg,
    aws_security_group.crm_vpc_loadbalancer_sg,
    aws_security_group.crm_vpc_bastion_sg
  ]
  name = "crm-vpc-app-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
  ingress {
    protocol = "tcp"
    from_port = 2000
    to_port = 2000
    security_groups = [aws_security_group.crm_vpc_nginx_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 2000
    to_port = 2000
    security_groups = [aws_security_group.crm_vpc_loadbalancer_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.crm_vpc_bastion_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crm-vpc-app-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "crm_vpc_nginx_sg" {
  depends_on = [
    aws_vpc.crm_vpc_net,
    aws_security_group.crm_vpc_loadbalancer_sg,
    aws_security_group.crm_vpc_bastion_sg
  ]
  name = "crm-vpc-nginx-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    security_groups = [aws_security_group.crm_vpc_loadbalancer_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.crm_vpc_bastion_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crm-vpc-nginx-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "crm_vpc_bastion_sg" {
  depends_on = [aws_vpc.crm_vpc_net]
  name = "crm-vpc-bastion-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
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
    Name = "crm-vpc-bastion-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "crm_vpc_nat_sg" {
  depends_on = [aws_vpc.crm_vpc_net]
  name = "crm-vpc-nat-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [var.environment == "prd" ? "11.1.0.0/16" : "12.1.0.0/16"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "crm-vpc-nat-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "crm_vpc_loadbalancer_sg" {
  depends_on = [aws_vpc.crm_vpc_net]
  name = "crm-vpc-loadbalancer-sg"
  vpc_id = aws_vpc.crm_vpc_net.id
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
    Name = "crm-vpc-loadbalancer-sg"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_s3_bucket" "crm_s3_app_stt_bkt" {
  bucket = "${var.s3_bucket_prefix}-sloopstash-${var.environment}-crm-s3-app-stt-bkt"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET","HEAD"]
    allowed_headers = ["*"]
    expose_headers = []
    max_age_seconds = 86400
  }
  tags = {
    Name = "${var.s3_bucket_prefix}-sloopstash-${var.environment}-crm-s3-app-stt-bkt"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_s3_bucket_public_access_block" "crm_s3_app_stt_bkt_pub_acs_blk" {
  depends_on = [aws_s3_bucket.crm_s3_app_stt_bkt]
  bucket = aws_s3_bucket.crm_s3_app_stt_bkt.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_cloudfront_origin_access_identity" "crm_cloud_front_app_oai" {
  comment = "crm-cloud-front-app-oai"
}
resource "aws_cloudfront_distribution" "crm_cloud_front_app_stt_dst" {
  depends_on = [
    aws_s3_bucket.crm_s3_app_stt_bkt,
    aws_cloudfront_origin_access_identity.crm_cloud_front_app_oai
  ]
  comment = "CRM CloudFront App static distribution."
  origin {
    domain_name = aws_s3_bucket.crm_s3_app_stt_bkt.bucket_regional_domain_name
    origin_id = "S3-${aws_s3_bucket.crm_s3_app_stt_bkt.id}"
    s3_origin_config {
      origin_access_identity = join("/",[
        "origin-access-identity",
        "cloudfront",
        aws_cloudfront_origin_access_identity.crm_cloud_front_app_oai.id
      ])
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET","HEAD"]
    cached_methods = ["GET","HEAD"]
    compress = true
    default_ttl = 86400
    min_ttl = 0
    max_ttl = 31536000
    smooth_streaming = false
    target_origin_id = "S3-${aws_s3_bucket.crm_s3_app_stt_bkt.id}"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
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
    Name = "crm-cloud-front-app-stt-dst"
    Environment = var.environment
    Stack = "crm"
    Organization = "sloopstash"
  }
}
resource "aws_key_pair" "crm_ec2_key_pair" {
  key_name = "crm-ec2-key-pair"
  public_key = var.ssh_public_key
  tags = {
    Name = "crm-ec2-key-pair"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_instance" "crm_ec2_bastion_inst_1" {
  depends_on = [
    aws_iam_instance_profile.crm_iam_ec2_rl_inst_pf,
    aws_vpc.crm_vpc_net,
    aws_subnet.crm_vpc_bastion_sn_1,
    aws_security_group.crm_vpc_bastion_sg
  ]
  iam_instance_profile = aws_iam_instance_profile.crm_iam_ec2_rl_inst_pf.id
  subnet_id = aws_subnet.crm_vpc_bastion_sn_1.id
  associate_public_ip_address = true
  private_dns_name_options {
    enable_resource_name_dns_aaaa_record = false
    enable_resource_name_dns_a_record = true
    hostname_type = "ip-name"
  }
  vpc_security_group_ids = [aws_security_group.crm_vpc_bastion_sg.id]
  ami = var.ec2_ami_id
  instance_type = "t3a.micro"
  key_name = aws_key_pair.crm_ec2_key_pair.id
  ebs_optimized = false
  credit_specification {
    cpu_credits = "standard"
  }
  cpu_options {
    core_count = 1
    threads_per_core = 2
  }
  instance_initiated_shutdown_behavior = "stop"
  disable_api_termination = false
  disable_api_stop = false
  hibernation = false
  tenancy = "default"
  monitoring = false
  tags = {
    Name = "crm-ec2-bastion-inst-1"
    Environment = var.environment
    Stack = "crm"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
