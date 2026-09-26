provider "aws" {
  region = "ap-south-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "tuto"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "iam_eks_rl" {
  name = "iam-eks-rl"
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
    Name = "iam-eks-rl"
    Organization = "sloopstash"
  }
}
resource "aws_iam_role_policy_attachment" "iam_eks_rl_plcy_1" {
  depends_on = [aws_iam_role.iam_eks_rl]
  role = aws_iam_role.iam_eks_rl.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_instance_profile" "iam_eks_rl_inst_pf" {
  depends_on = [aws_iam_role.iam_eks_rl]
  role = aws_iam_role.iam_eks_rl.name
  path = "/"
  tags = {
    Name = "iam-eks-rl-inst-pf"
    Organization = "sloopstash"
  }
}
resource "aws_subnet" "container_s2_vpc_kubernetes_sn_1" {
  depends_on = [var.vpc_net_id]
  vpc_id = var.vpc_net_id
  cidr_block = var.environment == "prd" ? "11.1.9.0/24" : "12.1.9.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "container-s2-vpc-kubernetes-sn-1"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_subnet" "container_s2_vpc_kubernetes_sn_2" {
  depends_on = [var.vpc_net_id]
  vpc_id = var.vpc_net_id
  cidr_block = var.environment == "prd" ? "11.1.10.0/24" : "12.1.10.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "container-s2-vpc-kubernetes-sn-2"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_route_table_association" "container_s2_vpc_kubernetes_sn_1_rtt_ass" {
  depends_on = [
    aws_subnet.container_s2_vpc_kubernetes_sn_1,
    var.vpc_pvt_rtt_id
  ]
  subnet_id = aws_subnet.container_s2_vpc_kubernetes_sn_1.id
  route_table_id = var.vpc_pvt_rtt_id
}
resource "aws_route_table_association" "container_s2_vpc_kubernetes_sn_2_rtt_ass" {
  depends_on = [
    aws_subnet.container_s2_vpc_kubernetes_sn_2,
    var.vpc_pvt_rtt_id
  ]
  subnet_id = aws_subnet.container_s2_vpc_kubernetes_sn_2.id
  route_table_id = var.vpc_pvt_rtt_id
}
resource "aws_security_group" "container_s2_vpc_kubernetes_sg" {
  depends_on = [
    var.vpc_net_id,
    var.vpc_bastion_sg_id,
    var.vpc_loadbalancer_sg_id
  ]
  name = "container-s2-vpc-kubernetes-sg"
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
    Name = "container-s2-vpc-kubernetes-sg"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_eks_cluster" "eks_ct" {
  depends_on = [
    aws_iam_role.iam_eks_rl,
    var.vpc_loadbalancer_sn_1_id,
    var.vpc_loadbalancer_sn_2_id,
    aws_subnet.container_s2_vpc_kubernetes_sn_1,
    aws_subnet.container_s2_vpc_kubernetes_sn_2,
    aws_security_group.container_s2_vpc_kubernetes_sg
  ]
  name = "eks-ct"
  role_arn = aws_iam_role.iam_eks_rl.arn
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = true
    subnet_ids = [
      var.vpc_loadbalancer_sn_1_id,
      var.vpc_loadbalancer_sn_2_id,
      aws_subnet.container_s2_vpc_kubernetes_sn_1.id,
      aws_subnet.container_s2_vpc_kubernetes_sn_2.id
    ]
    security_group_ids = [aws_security_group.container_s2_vpc_kubernetes_sg.id]
  }
  version = "1.36"
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
    Name = "eks-ct"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
resource "aws_eks_node_group" "eks_gnr_ng" {
  depends_on = [
    var.iam_ec2_rl_arn,
    aws_subnet.container_s2_vpc_kubernetes_sn_1,
    aws_subnet.container_s2_vpc_kubernetes_sn_2,
    var.vpc_bastion_sg_id,
    var.ec2_rsa_kp_id,
    aws_eks_cluster.eks_ct
  ]
  node_group_name = "eks-gnr-ng"
  cluster_name = aws_eks_cluster.eks_ct.name
  node_role_arn = var.iam_ec2_rl_arn
  subnet_ids = [
    aws_subnet.container_s2_vpc_kubernetes_sn_1.id,
    aws_subnet.container_s2_vpc_kubernetes_sn_2.id
  ]
  version = "1.36"
  ami_type = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"
  instance_types = ["t3a.small"]
  disk_size = 20
  force_update_version = true
  remote_access {
    ec2_ssh_key = var.ec2_rsa_kp_id
    source_security_group_ids = [var.vpc_bastion_sg_id]
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
    Name = "eks-gnr-ng"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = data.aws_region.current.name
    Organization = "sloopstash"
  }
}
