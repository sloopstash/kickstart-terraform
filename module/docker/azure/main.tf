provider "azurerm" {
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}

resource "azurerm_subnet" "container_s1_vnet_docker_sn_1" {
  depends_on = [
    var.rg_name,
    var.vnet_name
  ]
  name = "container-s1-vnet-docker-sn-1"
  resource_group_name = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes = [var.environment == "prd" ? "11.1.7.0/24" : "12.1.7.0/24"]
}
resource "azurerm_subnet" "container_s1_vnet_docker_sn_2" {
  depends_on = [
    var.rg_name,
    var.vnet_name
  ]
  name = "container-s1-vnet-docker-sn-2"
  resource_group_name = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes = [var.environment == "prd" ? "11.1.8.0/24" : "12.1.8.0/24"]
}
resource "azurerm_subnet_nat_gateway_association" "container_s1_vnet_docker_sn_1_ng_ass" {
  depends_on = [
    azurerm_subnet.container_s1_vnet_docker_sn_1,
    var.ng_id
  ]
  subnet_id = azurerm_subnet.container_s1_vnet_docker_sn_1.id
  nat_gateway_id = var.ng_id
}
resource "azurerm_subnet_nat_gateway_association" "container_s1_vnet_docker_sn_2_ng_ass" {
  depends_on = [
    azurerm_subnet.container_s1_vnet_docker_sn_2,
    var.ng_id
  ]
  subnet_id = azurerm_subnet.container_s1_vnet_docker_sn_2.id
  nat_gateway_id = var.ng_id
}
resource "azurerm_network_security_group" "container_s1_docker_nsg" {
  depends_on = [
    var.rg_name,
    var.rg_location
  ]
  name = "container-s1-docker-nsg"
  resource_group_name = var.rg_name
  location = var.rg_location
  tags = {
    Name = "container-s1-docker-nsg"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
