provider "azurerm" {
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "sloopstash-${var.environment}"
  location = "Central India"
  tags = {
    Name = "sloopstash-${var.environment}"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_virtual_network" "vnet" {
  depends_on = [azurerm_resource_group.rg]
  name = "vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = [var.environment == "prd" ? "11.1.0.0/16" : "12.1.0.0/16"]
  encryption {
    enforcement = "AllowUnencrypted"
  }
  tags = {
    Name = "vnet"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_subnet" "vnet_bastion_sn_1" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-bastion-sn-1"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.1.0/24" : "12.1.1.0/24"]
}
resource "azurerm_subnet" "vnet_bastion_sn_2" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-bastion-sn-2"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.2.0/24" : "12.1.2.0/24"]
}
resource "azurerm_subnet" "vnet_nat_sn_1" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-nat-sn-1"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.3.0/24" : "12.1.3.0/24"]
}
resource "azurerm_subnet" "vnet_nat_sn_2" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-nat-sn-2"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.4.0/24" : "12.1.4.0/24"]
}
resource "azurerm_subnet" "vnet_loadbalancer_sn_1" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-loadbalancer-sn-1"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.5.0/24" : "12.1.5.0/24"]
}
resource "azurerm_subnet" "vnet_loadbalancer_sn_2" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
  name = "vnet-loadbalancer-sn-2"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.6.0/24" : "12.1.6.0/24"]
}
resource "azurerm_public_ip" "nat_pip" {
  depends_on = [azurerm_resource_group.rg]
  name = "nat-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
  sku = "Standard"
  sku_tier = "Regional"
  idle_timeout_in_minutes = 4
  tags = {
    Name = "nat-pip"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_nat_gateway" "ng" {
  depends_on = [azurerm_resource_group.rg]
  name = "ng"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku_name = "Standard"
  idle_timeout_in_minutes = 4
  tags = {
    Name = "ng"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_nat_gateway_public_ip_association" "ng_pip_ass" {
  depends_on = [
    azurerm_public_ip.nat_pip,
    azurerm_nat_gateway.ng
  ]
  public_ip_address_id = azurerm_public_ip.nat_pip.id
  nat_gateway_id = azurerm_nat_gateway.ng.id
}
resource "azurerm_network_security_group" "bastion_nsg" {
  depends_on = [azurerm_resource_group.rg]
  name = "bastion-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  security_rule {
    name = "AllowAnyIpAddressSSHInbound"
    direction = "Inbound"
    access = "Allow"
    priority = 110
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = 22
  }
  tags = {
    Name = "bastion-nsg"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
