variable "environment" {
  type = string
  description = "Environment."
}
variable "ssh_public_key" {
  type = string
  description = "SSH public key."
}
variable "s3_bucket_prefix" {
  type = number
  description = "S3 bucket prefix."
}
variable "ec2_ami_id" {
  type = string
  description = "EC2 AMI identifier."
}
