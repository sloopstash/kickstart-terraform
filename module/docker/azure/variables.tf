variable "environment" {
  type = string
  description = "Environment."
}
variable "subscription_id" {
  type = string
  description = "Subscription identifier."
}
variable "rg_name" {
  type = string
  description = "Resource group name."
}
variable "rg_location" {
  type = string
  description = "Resource group location."
}
variable "vnet_name" {
  type = string
  description = "Virtual network name."
}
variable "ng_id" {
  type = string
  description = "NAT gateway identifier."
}
