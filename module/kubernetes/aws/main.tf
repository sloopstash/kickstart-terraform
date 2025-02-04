provider "aws" {
  region = "ap-south-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "tuto"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "kubernetes_iam_ec2_rl" {
  name = "kubernetes-iam-ec2-rl"
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
    Name = "kubernetes-iam-ec2-rl"
    Environment = var.environment
    Stack = "kubernetes"
    Organization = "sloopstash"
  }
}
resource "aws_iam_role_policy_attachment" "kubernetes_iam_ec2_rl_plcy_1" {
  depends_on = [aws_iam_role.kubernetes_iam_ec2_rl]
  role = aws_iam_role.kubernetes_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "kubernetes_iam_ec2_rl_plcy_2" {
  depends_on = [aws_iam_role.kubernetes_iam_ec2_rl]
  role = aws_iam_role.kubernetes_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "kubernetes_iam_ec2_rl_plcy_3" {
  depends_on = [aws_iam_role.kubernetes_iam_ec2_rl]
  role = aws_iam_role.kubernetes_iam_ec2_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_instance_profile" "kubernetes_iam_ec2_rl_inst_pf" {
  depends_on = [aws_iam_role.kubernetes_iam_ec2_rl]
  role = aws_iam_role.kubernetes_iam_ec2_rl.name
  path = "/"
  tags = {
    Name = "kubernetes-iam-ec2-rl-inst-pf"
    Environment = var.environment
    Stack = "kubernetes"
    Organization = "sloopstash"
  }
}
resource "aws_iam_role" "kubernetes_iam_eks_rl" {
  name = "kubernetes-iam-eks-rl"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  path = "/"
  tags = {
    Name = "kubernetes-iam-eks-rl"
    Environment = var.environment
    Stack = "kubernetes"
    Organization = "sloopstash"
  }
}
resource "aws_iam_role_policy_attachment" "kubernetes_iam_eks_rl_plcy_1" {
  depends_on = [aws_iam_role.kubernetes_iam_eks_rl]
  role = aws_iam_role.kubernetes_iam_eks_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_instance_profile" "kubernetes_iam_eks_rl_inst_pf" {
  depends_on = [aws_iam_role.kubernetes_iam_eks_rl]
  role = aws_iam_role.kubernetes_iam_eks_rl.name
  path = "/"
  tags = {
    Name = "kubernetes-iam-eks-rl-inst-pf"
    Environment = var.environment
    Stack = "kubernetes"
    Organization = "sloopstash"
  }
}
resource "aws_vpc" "kubernetes_vpc_net" {
  cidr_block = var.environment == "prd" ? "11.11.0.0/16" : "12.11.0.0/16"
  assign_generated_ipv6_cidr_block = false
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name = "kubernetes-vpc-net"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_internet_gateway" "kubernetes_vpc_ig" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  tags = {
    Name = "kubernetes-vpc-ig"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table" "kubernetes_vpc_pub_rtt" {
  depends_on = [
    aws_vpc.kubernetes_vpc_net,
    aws_internet_gateway.kubernetes_vpc_ig
  ]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_vpc_ig.id
  }
  tags = {
    Name = "kubernetes-vpc-pub-rtt"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table" "kubernetes_vpc_pvt_rtt" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  tags = {
    Name = "kubernetes-vpc-pvt-rtt"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route" "kubernetes_vpc_pvt_rtt_rt_1" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pvt_rtt,
    aws_nat_gateway.kubernetes_vpc_ng
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pvt_rtt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.kubernetes_vpc_ng.id
}
resource "aws_subnet" "kubernetes_vpc_bastion_sn_1" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.1.0/24" : "12.11.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "kubernetes-vpc-bastion-sn-1"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_bastion_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_bastion_sn_1
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_bastion_sn_1.id
}
resource "aws_subnet" "kubernetes_vpc_bastion_sn_2" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.2.0/24" : "12.11.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "kubernetes-vpc-bastion-sn-2"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_bastion_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_bastion_sn_2
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_bastion_sn_2.id
}
resource "aws_subnet" "kubernetes_vpc_nat_sn_1" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.3.0/24" : "12.11.3.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "kubernetes-vpc-nat-sn-1"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_nat_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_nat_sn_1
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_nat_sn_1.id
}
resource "aws_subnet" "kubernetes_vpc_nat_sn_2" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.4.0/24" : "12.11.4.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "kubernetes-vpc-nat-sn-2"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_nat_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_nat_sn_2
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_nat_sn_2.id
}
resource "aws_subnet" "kubernetes_vpc_loadbalancer_sn_1" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.5.0/24" : "12.11.5.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "kubernetes-vpc-loadbalancer-sn-1"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_loadbalancer_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_loadbalancer_sn_1
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_loadbalancer_sn_1.id
}
resource "aws_subnet" "kubernetes_vpc_loadbalancer_sn_2" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.6.0/24" : "12.11.6.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "kubernetes-vpc-loadbalancer-sn-2"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_loadbalancer_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_loadbalancer_sn_2
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_loadbalancer_sn_2.id
}
resource "aws_subnet" "kubernetes_vpc_eks_cp_sn_1" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.7.0/24" : "12.11.7.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "kubernetes-vpc-eks-cp-sn-1"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_eks_cp_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_eks_cp_sn_1
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_eks_cp_sn_1.id
}
resource "aws_subnet" "kubernetes_vpc_eks_cp_sn_2" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.8.0/24" : "12.11.8.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "kubernetes-vpc-eks-cp-sn-2"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_eks_cp_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pub_rtt,
    aws_subnet.kubernetes_vpc_eks_cp_sn_2
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pub_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_eks_cp_sn_2.id
}
resource "aws_subnet" "kubernetes_vpc_eks_nd_sn_1" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.9.0/24" : "12.11.9.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "kubernetes-vpc-eks-nd-sn-1"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_eks_nd_sn_1_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pvt_rtt,
    aws_subnet.kubernetes_vpc_eks_nd_sn_1
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pvt_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_eks_nd_sn_1.id
}
resource "aws_subnet" "kubernetes_vpc_eks_nd_sn_2" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  cidr_block = var.environment == "prd" ? "11.11.10.0/24" : "12.11.10.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "kubernetes-vpc-eks-nd-sn-2"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "kubernetes_vpc_eks_nd_sn_2_rtt_ass" {
  depends_on = [
    aws_route_table.kubernetes_vpc_pvt_rtt,
    aws_subnet.kubernetes_vpc_eks_nd_sn_2
  ]
  route_table_id = aws_route_table.kubernetes_vpc_pvt_rtt.id
  subnet_id = aws_subnet.kubernetes_vpc_eks_nd_sn_2.id
}
resource "aws_eip" "kubernetes_vpc_nat_eip" {
  network_border_group = data.aws_region.current.name
  public_ipv4_pool = "amazon"
  domain = "vpc"
  tags = {
    Name = "kubernetes-vpc-nat-eip"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_nat_gateway" "kubernetes_vpc_ng" {
  depends_on = [
    aws_subnet.kubernetes_vpc_nat_sn_2,
    aws_eip.kubernetes_vpc_nat_eip
  ]
  subnet_id = aws_subnet.kubernetes_vpc_nat_sn_2.id
  allocation_id = aws_eip.kubernetes_vpc_nat_eip.id
  connectivity_type = "public"
  tags = {
    Name = "kubernetes-vpc-ng"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "kubernetes_vpc_bastion_sg" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  name = "kubernetes-vpc-bastion-sg"
  vpc_id = aws_vpc.kubernetes_vpc_net.id
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
    Name = "kubernetes-vpc-bastion-sg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "kubernetes_vpc_nat_sg" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  name = "kubernetes-vpc-nat-sg"
  vpc_id = aws_vpc.kubernetes_vpc_net.id
  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [var.environment == "prd" ? "11.11.0.0/16" : "12.11.0.0/16"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kubernetes-vpc-nat-sg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "kubernetes_vpc_loadbalancer_sg" {
  depends_on = [aws_vpc.kubernetes_vpc_net]
  name = "kubernetes-vpc-loadbalancer-sg"
  vpc_id = aws_vpc.kubernetes_vpc_net.id
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
    Name = "kubernetes-vpc-loadbalancer-sg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_security_group" "kubernetes_vpc_eks_sg" {
  depends_on = [
    aws_vpc.kubernetes_vpc_net,
    aws_security_group.kubernetes_vpc_bastion_sg
  ]
  name = "kubernetes-vpc-eks-sg"
  vpc_id = aws_vpc.kubernetes_vpc_net.id
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
    security_groups = [aws_security_group.kubernetes_vpc_bastion_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kubernetes-vpc-eks-sg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_key_pair" "kubernetes_ec2_key_pair" {
  key_name = "kubernetes-ec2-key-pair"
  public_key = var.ssh_public_key
  tags = {
    Name = "kubernetes-ec2-key-pair"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "kubernetes_ecr_redis_repo" {
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
    Name = "kubernetes-ecr-redis-repo"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "kubernetes_ecr_python_repo" {
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
    Name = "kubernetes-ecr-python-repo"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_ecr_repository" "kubernetes_ecr_nginx_repo" {
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
    Name = "kubernetes-ecr-nginx-repo"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_eks_cluster" "kubernetes_eks_ct" {
  depends_on = [
    aws_iam_role.kubernetes_iam_eks_rl,
    aws_subnet.kubernetes_vpc_eks_cp_sn_1,
    aws_subnet.kubernetes_vpc_eks_cp_sn_2,
    aws_subnet.kubernetes_vpc_eks_nd_sn_1,
    aws_subnet.kubernetes_vpc_eks_nd_sn_2,
    aws_security_group.kubernetes_vpc_eks_sg
  ]
  name = "kubernetes-eks-ct"
  role_arn = aws_iam_role.kubernetes_iam_eks_rl.arn
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = true
    subnet_ids = [
      aws_subnet.kubernetes_vpc_eks_cp_sn_1.id,
      aws_subnet.kubernetes_vpc_eks_cp_sn_2.id,
      aws_subnet.kubernetes_vpc_eks_nd_sn_1.id,
      aws_subnet.kubernetes_vpc_eks_nd_sn_2.id
    ]
    security_group_ids = [aws_security_group.kubernetes_vpc_eks_sg.id]
  }
  version = "1.29"
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  bootstrap_self_managed_addons = true
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = false
    }
    ip_family = "ipv4"
  }
  storage_config {
    block_storage {
      enabled = false
    }
  }
  compute_config {
    enabled = false
  }
  zonal_shift_config {
    enabled = false
  }
  tags = {
    Name = "kubernetes-eks-ct"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_eks_node_group" "kubernetes_eks_gnr_ng" {
  depends_on = [
    aws_iam_role.kubernetes_iam_ec2_rl,
    aws_subnet.kubernetes_vpc_eks_nd_sn_1,
    aws_subnet.kubernetes_vpc_eks_nd_sn_2,
    aws_security_group.kubernetes_vpc_bastion_sg,
    aws_key_pair.kubernetes_ec2_key_pair,
    aws_eks_cluster.kubernetes_eks_ct
  ]
  node_group_name = "kubernetes-eks-gnr-ng"
  cluster_name = aws_eks_cluster.kubernetes_eks_ct.name
  node_role_arn = aws_iam_role.kubernetes_iam_ec2_rl.arn
  subnet_ids = [
    aws_subnet.kubernetes_vpc_eks_nd_sn_1.id,
    aws_subnet.kubernetes_vpc_eks_nd_sn_2.id
  ]
  version = "1.29"
  ami_type = "AL2_x86_64"
  capacity_type = "ON_DEMAND"
  instance_types = ["t3a.small"]
  disk_size = 8
  force_update_version = true
  remote_access {
    ec2_ssh_key = aws_key_pair.kubernetes_ec2_key_pair.id
    source_security_group_ids = [aws_security_group.kubernetes_vpc_bastion_sg.id]
  }
  update_config {
    max_unavailable_percentage = 30
  }
  scaling_config {
    desired_size = 1
    max_size = 1
    min_size = 1
  }
  tags = {
    Name = "kubernetes-eks-gnr-ng"
    Environment = var.environment
    Stack = "kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
