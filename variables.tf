variable "env" {
  type = string
  description = "Environment."
}
variable "aws_s3_bucket_prefix" {
  type = string
  description = "AWS S3 bucket prefix."
}
variable "ssh_public_key" {
  type = string
  description = "SSH public key."
}
