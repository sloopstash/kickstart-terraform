variable "environment" {
  type = string
  description = "Environment."
}
variable "ssh_public_key" {
  type = string
  description = "SSH public key."
}
variable "aws_s3_bucket_prefix" {
  type = number
  description = "Amazon S3 bucket prefix."
}
variable "aws_ec2_ami_id" {
  type = string
  description = "Amazon EC2 AMI identifier."
}
variable "azure_subscription_id" {
  type = string
  description = "Azure subscription identifier."
}
