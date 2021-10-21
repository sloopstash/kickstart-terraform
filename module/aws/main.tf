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
resource "aws_subnet" "vpc_app_sn_1" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.1.0/24" : "12.1.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "${var.env}-vpc-app-sn-1"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_app_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_app_sn_1,
    aws_route_table.vpc_pvt_rtt
  ]
  subnet_id = aws_subnet.vpc_app_sn_1.id
  route_table_id = aws_route_table.vpc_pvt_rtt.id
}
resource "aws_subnet" "vpc_app_sn_2" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.2.0/24" : "12.1.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "${var.env}-vpc-app-sn-2"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_app_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_app_sn_2,
    aws_route_table.vpc_pvt_rtt
  ]
  subnet_id = aws_subnet.vpc_app_sn_2.id
  route_table_id = aws_route_table.vpc_pvt_rtt.id
}
resource "aws_subnet" "vpc_redis_sn_1" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.3.0/24" : "12.1.3.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "${var.env}-vpc-redis-sn-1"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_redis_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_redis_sn_1,
    aws_route_table.vpc_pvt_rtt
  ]
  subnet_id = aws_subnet.vpc_redis_sn_1.id
  route_table_id = aws_route_table.vpc_pvt_rtt.id
}
resource "aws_subnet" "vpc_redis_sn_2" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.4.0/24" : "12.1.4.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "${var.env}-vpc-redis-sn-2"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_redis_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_redis_sn_2,
    aws_route_table.vpc_pvt_rtt
  ]
  subnet_id = aws_subnet.vpc_redis_sn_2.id
  route_table_id = aws_route_table.vpc_pvt_rtt.id
}
resource "aws_subnet" "vpc_nat_sn_1" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.5.0/24" : "12.1.5.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "${var.env}-vpc-nat-sn-1"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_nat_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_nat_sn_1,
    aws_route_table.vpc_pub_rtt
  ]
  subnet_id = aws_subnet.vpc_nat_sn_1.id
  route_table_id = aws_route_table.vpc_pub_rtt.id
}
resource "aws_subnet" "vpc_nat_sn_2" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.6.0/24" : "12.1.6.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "${var.env}-vpc-nat-sn-2"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_nat_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_nat_sn_2,
    aws_route_table.vpc_pub_rtt
  ]
  subnet_id = aws_subnet.vpc_nat_sn_2.id
  route_table_id = aws_route_table.vpc_pub_rtt.id
}
resource "aws_subnet" "vpc_loadbalancer_sn_1" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.7.0/24" : "12.1.7.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "${var.env}-vpc-loadbalancer-sn-1"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_loadbalancer_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_loadbalancer_sn_1,
    aws_route_table.vpc_pub_rtt
  ]
  subnet_id = aws_subnet.vpc_loadbalancer_sn_1.id
  route_table_id = aws_route_table.vpc_pub_rtt.id
}
resource "aws_subnet" "vpc_loadbalancer_sn_2" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  cidr_block = var.env == "prd" ? "11.1.8.0/24" : "12.1.8.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "${var.env}-vpc-loadbalancer-sn-2"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_route_table_association" "vpc_loadbalancer_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.vpc_loadbalancer_sn_2,
    aws_route_table.vpc_pub_rtt
  ]
  subnet_id = aws_subnet.vpc_loadbalancer_sn_2.id
  route_table_id = aws_route_table.vpc_pub_rtt.id
}
resource "aws_security_group" "vpc_app_sg" {
  depends_on = [
    aws_vpc.vpc_net,
    aws_security_group.vpc_loadbalancer_sg,
    aws_security_group.vpc_nat_sg
  ]
  vpc_id = aws_vpc.vpc_net.id
  name = "${var.env}-vpc-app-sg"
  ingress {
    protocol = "tcp"
    from_port = 5000
    to_port = 5000
    security_groups = [aws_security_group.vpc_loadbalancer_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.vpc_nat_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-vpc-app-sg"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_security_group" "vpc_redis_sg" {
  depends_on = [
    aws_vpc.vpc_net,
    aws_security_group.vpc_app_sg,
    aws_security_group.vpc_nat_sg
  ]
  vpc_id = aws_vpc.vpc_net.id
  name = "${var.env}-vpc-redis-sg"
  ingress {
    protocol = "tcp"
    from_port = 6379
    to_port = 6379
    security_groups = [aws_security_group.vpc_app_sg.id]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [aws_security_group.vpc_nat_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-vpc-redis-sg"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_security_group" "vpc_nat_sg" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  name = "${var.env}-vpc-nat-sg"
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [aws_vpc.vpc_net.cidr_block]
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
    Name = "${var.env}-vpc-nat-sg"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_security_group" "vpc_loadbalancer_sg" {
  depends_on = [aws_vpc.vpc_net]
  vpc_id = aws_vpc.vpc_net.id
  name = "${var.env}-vpc-loadbalancer-sg"
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
    cidr_blocks = [aws_vpc.vpc_net.cidr_block]
  }
  tags = {
    Name = "${var.env}-vpc-loadbalancer-sg"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_s3_bucket" "s3_app_stt_bkt" {
  bucket = "${var.s3_bucket_prefix}-${var.env}-s3-app-stt-bkt"
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
    Name = "${var.env}-s3-app-stt-bkt"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_s3_bucket_policy" "s3_app_stt_bkt_plcy" {
  depends_on = [
    aws_s3_bucket.s3_app_stt_bkt,
    aws_cloudfront_origin_access_identity.cloud_front_app_oai
  ]
  bucket = aws_s3_bucket.s3_app_stt_bkt.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "001"
      Effect = "Allow"
      Principal = {
        AWS = "${aws_cloudfront_origin_access_identity.cloud_front_app_oai.iam_arn}"
      }
      Action = [
        "s3:GetObject"
      ]
      Resource = [
        join(":::",[
          "arn:aws:s3",
          "${aws_s3_bucket.s3_app_stt_bkt.id}/*"
        ])
      ]
    }]
  })
}
resource "aws_s3_bucket_public_access_block" "s3_app_stt_bkt_pub_acs_blk" {
  depends_on = [
    aws_s3_bucket.s3_app_stt_bkt,
    aws_s3_bucket_policy.s3_app_stt_bkt_plcy
  ]
  bucket = aws_s3_bucket.s3_app_stt_bkt.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true 
}
resource "aws_cloudfront_origin_access_identity" "cloud_front_app_oai" {
  comment = "${var.env}-cloud-front-app-oai"
}
resource "aws_cloudfront_distribution" "cloud_front_app_stt_dst" {
  depends_on = [
    aws_s3_bucket.s3_app_stt_bkt,
    aws_cloudfront_origin_access_identity.cloud_front_app_oai
  ]
  comment = "CloudFront App static distribution."
  origin {
    domain_name = aws_s3_bucket.s3_app_stt_bkt.bucket_regional_domain_name
    origin_id = "S3-${aws_s3_bucket.s3_app_stt_bkt.id}"
    s3_origin_config {
      origin_access_identity = join("/",[
        "origin-access-identity",
        "cloudfront",
        aws_cloudfront_origin_access_identity.cloud_front_app_oai.id
      ])
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET","HEAD","OPTIONS"]
    cached_methods = ["GET","HEAD","OPTIONS"]
    compress = true
    default_ttl = 86400
    min_ttl = 0
    max_ttl = 31536000
    smooth_streaming = false
    target_origin_id = "S3-${aws_s3_bucket.s3_app_stt_bkt.id}"
    viewer_protocol_policy = "https-only"
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
    Name = "${var.env}-cloud-front-app-stt-dst"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_key_pair" "ec2_key_pair" {
  key_name = "${var.env}-ec2-key-pair"
  public_key = var.ssh_public_key
  tags = {
    Name = "${var.env}-ec2-key-pair"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
resource "aws_lb_target_group" "ec2_app_tg" {
  depends_on = [aws_vpc.vpc_net]
  name = "${var.env}-ec2-app-tg"
  port = 5000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.vpc_net.id
  health_check {
    enabled = true
    healthy_threshold = 3
    interval = 30
    matcher = "200"
    path = "/Health"
    port = 5000
    protocol = "HTTP"
    timeout = 10
    unhealthy_threshold = 3
  }
  tags = {
    Name = "${var.env}-ec2-app-tg"
    Environment = var.env
    Region = data.aws_region.current.name
    Product = "crm"
  }
}
