variable "environment" {
  type = string
  description = "Environment."
}
variable "ssh_public_key" {
  type = string
  description = "SSH public key."
}
variable "subscription_id" {
  type = string
  description = "Subscription identifier."
}
variable "vm_image_id" {
  type        = string
  description = "Managed Image ID"
}
variable "storage_account_prefix" {
  description = "Storage Account Prefix"
  type        = string
}
variable "my_ip" {
  description = "Your public IP address"
  type        = string
}

