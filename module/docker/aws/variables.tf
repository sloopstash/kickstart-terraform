variable "environment" {
  type = string
  description = "Environment."
}
variable "vpc_net_id" {
  type = string
  description = "VPC network identifier."
}
variable "vpc_pvt_rtt_id" {
  type = string
  description = "VPC private route table identifier."
}
variable "vpc_bastion_sg_id" {
  type = string
  description = "VPC bastion security group identifier."
}
variable "vpc_loadbalancer_sg_id" {
  type = string
  description = "VPC loadbalancer security group identifier."
}
