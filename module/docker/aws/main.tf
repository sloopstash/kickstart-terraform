provider "aws" {
  region = "ap-south-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "tuto"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_subnet" "container_s1_vpc_docker_sn_1" {
  depends_on = [var.vpc_net_id]
  vpc_id = var.vpc_net_id
  cidr_block = var.environment == "prd" ? "11.1.7.0/24" : "12.1.7.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "container-s1-vpc-docker-sn-1"
    Environment = var.environment
    Stack = "container-s1/docker"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_subnet" "container_s1_vpc_docker_sn_2" {
  depends_on = [var.vpc_net_id]
  vpc_id = var.vpc_net_id
  cidr_block = var.environment == "prd" ? "11.1.8.0/24" : "12.1.8.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "container-s1-vpc-docker-sn-2"
    Environment = var.environment
    Stack = "container-s1/docker"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "container_s1_vpc_docker_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.container_s1_vpc_docker_sn_1,
    var.vpc_pvt_rtt_id
  ]
  subnet_id = aws_subnet.container_s1_vpc_docker_sn_1.id
  route_table_id = var.vpc_pvt_rtt_id
}
resource "aws_route_table_association" "container_s1_vpc_docker_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.container_s1_vpc_docker_sn_2,
    var.vpc_pvt_rtt_id
  ]
  subnet_id = aws_subnet.container_s1_vpc_docker_sn_2.id
  route_table_id = var.vpc_pvt_rtt_id
}
resource "aws_security_group" "container_s1_vpc_docker_sg" {
  depends_on = [
    var.vpc_net_id,
    var.vpc_bastion_sg_id,
    var.vpc_loadbalancer_sg_id
  ]
  name = "container-s1-vpc-docker-sg"
  vpc_id = var.vpc_net_id
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    self = true
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_groups = [var.vpc_bastion_sg_id]
  }
  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    security_groups = [var.vpc_loadbalancer_sg_id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "container-s1-vpc-docker-sg"
    Environment = var.environment
    Stack = "container-s1/docker"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "ecr_redis_repo" {
  name = "sloopstash/redis"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = {
    Name = "ecr-redis-repo"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "ecr_chroma_repo" {
  name = "sloopstash/chroma"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = {
    Name = "ecr-chroma-repo"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "ecr_ollama_repo" {
  name = "sloopstash/ollama"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = {
    Name = "ecr-ollama-repo"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "ecr_python_repo" {
  name = "sloopstash/python"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = {
    Name = "ecr-python-repo"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "ecr_nginx_repo" {
  name = "sloopstash/nginx"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = {
    Name = "ecr-nginx-repo"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
