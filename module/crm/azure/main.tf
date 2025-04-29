provider "azurerm" {
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}
resource "azurerm_resource_group" "crm_rg" {
  name = "crm-rg"
  location = "Central India"
  tags = {
    Name = "crm-rg"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}

resource "azurerm_virtual_network" "crm_vnet" {
  depends_on = [azurerm_resource_group.crm_rg]
  name = "crm-vnet"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location = azurerm_resource_group.crm_rg.location
  address_space = [var.environment == "prd" ? "11.1.0.0/16" : "12.1.0.0/16"]
  encryption {
    enforcement = "AllowUnencrypted"
  }
  tags = {
    Name = "crm-vnet"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}

resource "azurerm_subnet" "crm_vnet_bastion_sn_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-bastion-sn-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.7.0/24" : "12.1.7.0/24"]
}
resource "azurerm_subnet" "crm_vnet_bastion_sn_2" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-bastion-sn-2"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.8.0/24" : "12.1.8.0/24"]
}
resource "azurerm_subnet" "crm_vnet_nginx_sn_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-nginx-sn-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.5.0/24" : "12.1.5.0/24"]
}
resource "azurerm_subnet" "crm_vnet_nginx_sn_2" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-nginx-sn-2"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.6.0/24" : "12.1.6.0/24"]
}
resource "azurerm_subnet" "crm_vnet_app_sn_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-app-sn-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.3.0/24" : "12.1.3.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet" "crm_vnet_app_sn_2" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-app-sn-2"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.4.0/24" : "12.1.4.0/24"]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet" "crm_vnet_redis_sn_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-redis-sn-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.1.0/24" : "12.1.1.0/24"]
}
resource "azurerm_subnet" "crm_vnet_redis_sn_2" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name = "crm-vnet-redis-sn-2"
  resource_group_name = azurerm_resource_group.crm_rg.name
  virtual_network_name = azurerm_virtual_network.crm_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.1.2.0/24" : "12.1.2.0/24"]
}
resource "azurerm_public_ip" "crm_public_ip" {
  depends_on = [azurerm_resource_group.crm_rg]
  for_each            = toset(["nat", "bastion", "loadbalancer"])
  name                = "crm-${each.value}-pip"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  zones              = ["1"]
  allocation_method   = "Static"
  tags = {
    Name = "crm-${each.value}-pip"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_nat_gateway" "crm_nat_gateway" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet]
  name                    = "crm-nat-gateway"
  resource_group_name     = azurerm_resource_group.crm_rg.name
  location                = azurerm_resource_group.crm_rg.location
  sku_name                = "Standard"
  zones                   = ["1"]
  tags = {
    Name = "crm-nat-gateway"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_nat_gateway_public_ip_association" "crm_nat_gateway_ip_association" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_nat_gateway.crm_nat_gateway]
  nat_gateway_id       = azurerm_nat_gateway.crm_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.crm_public_ip["nat"].id
}
locals {
  subnets = {
    "crm_vnet_app_sn_1"   = azurerm_subnet.crm_vnet_app_sn_1.id
    "crm_vnet_app_sn_2"   = azurerm_subnet.crm_vnet_app_sn_2.id
    "crm_vnet_nginx_sn_1" = azurerm_subnet.crm_vnet_nginx_sn_1.id
    "crm_vnet_nginx_sn_2" = azurerm_subnet.crm_vnet_nginx_sn_2.id
    "crm_vnet_redis_sn_1" = azurerm_subnet.crm_vnet_redis_sn_1.id
    "crm_vnet_redis_sn_2" = azurerm_subnet.crm_vnet_redis_sn_2.id
  }
}
resource "azurerm_subnet_nat_gateway_association" "crm_nat_gateway_subnet_association" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_subnet.crm_vnet_app_sn_1,
                azurerm_subnet.crm_vnet_app_sn_2, azurerm_subnet.crm_vnet_nginx_sn_1,
                azurerm_subnet.crm_vnet_nginx_sn_2, azurerm_subnet.crm_vnet_redis_sn_1,
                azurerm_subnet.crm_vnet_redis_sn_2]
  for_each       = local.subnets
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.crm_nat_gateway.id
}
resource "azurerm_network_security_group" "crm_redis_nsg" {
  depends_on = [azurerm_resource_group.crm_rg]
  name                = "crm-redis-nsg"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  tags = {
  Name         = "crm-redis-nsg"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_subnet_network_security_group_association" "crm_redis_subnet_nsg_association-1" {
  depends_on = [azurerm_network_security_group.crm_redis_nsg,azurerm_subnet.crm_vnet_redis_sn_1]
  subnet_id      = azurerm_subnet.crm_vnet_redis_sn_1.id
  network_security_group_id = azurerm_network_security_group.crm_redis_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "crm_redis_subnet_nsg_association-2" {
  depends_on = [azurerm_network_security_group.crm_redis_nsg,azurerm_subnet.crm_vnet_redis_sn_2] 
  subnet_id      = azurerm_subnet.crm_vnet_redis_sn_2.id
  network_security_group_id = azurerm_network_security_group.crm_redis_nsg.id
}
resource "azurerm_network_security_group" "crm_app_nsg" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_subnet_nat_gateway_association.crm_nat_gateway_subnet_association]
  name                = "crm-app-nsg"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  security_rule {
    name                       = "AllowAnyCustom2000Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefixes = var.environment == "prd" ? ["11.1.3.0/24", "11.1.4.0/24"] : ["12.1.3.0/24", "12.1.4.0/24"]
  }
  tags = {
  Name         = "crm-app-nsg"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_subnet_network_security_group_association" "crm_app_subnet_nsg_association-1" {
  depends_on = [azurerm_network_security_group.crm_app_nsg,azurerm_subnet.crm_vnet_app_sn_1]
  subnet_id      = azurerm_subnet.crm_vnet_app_sn_1.id
  network_security_group_id = azurerm_network_security_group.crm_app_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "crm_app_subnet_nsg_association-2" {
  depends_on = [azurerm_network_security_group.crm_app_nsg,azurerm_subnet.crm_vnet_app_sn_2] 
  subnet_id      = azurerm_subnet.crm_vnet_app_sn_2.id
  network_security_group_id = azurerm_network_security_group.crm_app_nsg.id
}
resource "azurerm_network_security_group" "crm_nginx_nsg" {
  depends_on = [azurerm_resource_group.crm_rg]
  name                = "crm-nginx-nsg"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  tags = {
  Name         = "crm-nginx-nsg"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_subnet_network_security_group_association" "crm_nginx_subnet_nsg_association-1" {
  depends_on = [azurerm_network_security_group.crm_nginx_nsg,azurerm_subnet.crm_vnet_nginx_sn_1]
  subnet_id      = azurerm_subnet.crm_vnet_nginx_sn_1.id
  network_security_group_id = azurerm_network_security_group.crm_nginx_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "crm_nginx_subnet_nsg_association-2" {
  depends_on = [azurerm_network_security_group.crm_nginx_nsg,azurerm_subnet.crm_vnet_nginx_sn_2] 
  subnet_id      = azurerm_subnet.crm_vnet_nginx_sn_2.id
  network_security_group_id = azurerm_network_security_group.crm_nginx_nsg.id
}
resource "azurerm_network_security_group" "crm_bastion_nsg" {
  depends_on = [azurerm_resource_group.crm_rg]
  name                = "crm-bastion-nsg"
  location            = azurerm_resource_group.crm_rg.location
  resource_group_name = azurerm_resource_group.crm_rg.name
  security_rule {
    name                       = "AllowAnyCustom2000Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.my_ip}/32"
    destination_address_prefix = "*"
  }
  tags = {
  Name         = "crm-bastion-nsg"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_subnet_network_security_group_association" "crm_bastion_subnet_nsg_association-1" {
  depends_on = [azurerm_network_security_group.crm_bastion_nsg,azurerm_subnet.crm_vnet_bastion_sn_1]
  subnet_id      = azurerm_subnet.crm_vnet_bastion_sn_1.id
  network_security_group_id = azurerm_network_security_group.crm_bastion_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "crm_bastion_subnet_nsg_association-2" {
  depends_on = [azurerm_network_security_group.crm_bastion_nsg,azurerm_subnet.crm_vnet_bastion_sn_2] 
  subnet_id      = azurerm_subnet.crm_vnet_bastion_sn_2.id
  network_security_group_id = azurerm_network_security_group.crm_bastion_nsg.id
}
resource "azurerm_network_interface" "crm_bastion_nic" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_subnet.crm_vnet_bastion_sn_1, azurerm_public_ip.crm_public_ip]
  name = "crm-bastion-nic"
  location = azurerm_resource_group.crm_rg.location
  resource_group_name = azurerm_resource_group.crm_rg.name
  ip_configuration {
    name = "crm-bastion-ip"
    subnet_id = azurerm_subnet.crm_vnet_bastion_sn_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.crm_public_ip["bastion"].id
  }
  tags = {
    Name = "crm-bastion-nic"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_network_interface" "crm_nginx_nic" {
   depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_subnet.crm_vnet_nginx_sn_1]
  name = "crm-nginx-nic"
  location = azurerm_resource_group.crm_rg.location
  resource_group_name = azurerm_resource_group.crm_rg.name
  ip_configuration {
    name = "crm-nginx-ip"
    subnet_id = azurerm_subnet.crm_vnet_nginx_sn_1.id
    private_ip_address_allocation = "Dynamic" 
  }
  tags = {
    Name = "crm-nginx-nic"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_network_interface" "crm_app_nic" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_subnet.crm_vnet_app_sn_1]
  name = "crm-app-nic"
  location = azurerm_resource_group.crm_rg.location
  resource_group_name = azurerm_resource_group.crm_rg.name
  ip_configuration {
    name = "crm-app-ipconfig"
    subnet_id = azurerm_subnet.crm_vnet_app_sn_1.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true 
  }
  tags = {
    Name = "crm-app-nic"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_network_interface" "crm_redis_nic" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_subnet.crm_vnet_redis_sn_1]
  name = "crm-redis-nic"
  location = azurerm_resource_group.crm_rg.location
  resource_group_name = azurerm_resource_group.crm_rg.name
  ip_configuration {
    name = "crm-redis-ip"
    subnet_id = azurerm_subnet.crm_vnet_redis_sn_1.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Name = "crm-redis-nic"
    Environment = var.environment
    Stack = "crm"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_linux_virtual_machine" "crm_bastion_vm_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_network_interface.crm_bastion_nic]
  name                = "crm-bastion-vm-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.crm_bastion_nic.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.vm_image_id
  tags = {
  Name         = "crm-bastion-vm-1"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_linux_virtual_machine" "crm_nginx_vm_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_network_interface.crm_nginx_nic]
  name                = "crm-nginx-vm-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.crm_nginx_nic.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.vm_image_id
  tags = {
  Name         = "crm-nginx-vm-1"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_linux_virtual_machine" "crm_app_vm_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_network_interface.crm_app_nic]
  name                = "crm-app-vm-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.crm_app_nic.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.vm_image_id
  tags = {
  Name         = "crm-app-vm-1"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_linux_virtual_machine" "crm_redis_vm_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, azurerm_network_interface.crm_redis_nic]
  name                = "crm-redis-vm-1"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.crm_redis_nic.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.vm_image_id
  tags = {
  Name         = "crm-redis-vm-1"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_storage_account" "crm_storage_account" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_virtual_network.crm_vnet, 
     azurerm_subnet.crm_vnet_app_sn_1, azurerm_subnet.crm_vnet_app_sn_2]
  name                     = "${var.storage_account_prefix}crmappsttst"
  resource_group_name      = azurerm_resource_group.crm_rg.name
  location                 = azurerm_resource_group.crm_rg.location
  account_tier             = "Standard"
  allow_nested_items_to_be_public = true
  public_network_access_enabled = true
  account_replication_type = "GRS"
  network_rules {
    default_action     = "Deny" 
    virtual_network_subnet_ids = [azurerm_subnet.crm_vnet_app_sn_1.id, azurerm_subnet.crm_vnet_app_sn_2.id]
  }
  tags = {
  Name         = "${var.storage_account_prefix}crmappsttst"
  Environment  = var.environment
  Stack        = "crm"
  Region       = "centralindia"
  Organization = "sloopstash"
  }
}
resource "azurerm_storage_container" "crm_storage_library_container" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_storage_account.crm_storage_account]
  name                  = "library"
  storage_account_id    = azurerm_storage_account.crm_storage_account.id
  container_access_type = "blob"
}
resource "azurerm_storage_container" "crm_storage_theme_container" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_storage_account.crm_storage_account]
  name                  = "theme"
  storage_account_id    = azurerm_storage_account.crm_storage_account.id
  container_access_type = "blob"
}
resource "azurerm_storage_container" "crm_storage_asset_container" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_storage_account.crm_storage_account]
  name                  = "asset"
  storage_account_id    = azurerm_storage_account.crm_storage_account.id
  container_access_type = "blob"
}
resource "azurerm_cdn_profile" "crm_cdn_profile" {
  depends_on = [azurerm_resource_group.crm_rg]
  name                = "crm-cdn-profile"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location             = azurerm_resource_group.crm_rg.location
  sku                 = "Standard_Microsoft" 
  tags = {
    Name         = "crm-cdn-profile"
    Environment  = var.environment
    Stack        = "crm"
    Region       = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_cdn_endpoint" "crm_cdn_endpoint" {
  resource_group_name = azurerm_resource_group.crm_rg.name
  location             = azurerm_resource_group.crm_rg.location
  name                = "${var.storage_account_prefix}-crm-app-stt-cdne"
  profile_name        = azurerm_cdn_profile.crm_cdn_profile.name
  origin {
    name      = "storage-origin"
    host_name = "${var.storage_account_prefix}crmappsttst.blob.core.windows.net"
  }
    origin_host_header = "${var.storage_account_prefix}crmappsttst.blob.core.windows.net"
    querystring_caching_behaviour = "UseQueryString"
}
resource "azurerm_lb" "crm_app_lb" {
  depends_on = [azurerm_resource_group.crm_rg,azurerm_public_ip.crm_public_ip["loadbalancer"]]
  name                = "crm-app-lb"
  resource_group_name = azurerm_resource_group.crm_rg.name
  location            = azurerm_resource_group.crm_rg.location
  frontend_ip_configuration {
    name                 = "frontend-ip-1"
    public_ip_address_id = azurerm_public_ip.crm_public_ip["loadbalancer"].id
  }
  tags = {
    Name         = "crm-app-lb"
    Environment  = var.environment
    Stack        = "crm"
    Region       = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_lb_backend_address_pool" "backend_pool_1" {
  depends_on = [azurerm_resource_group.crm_rg, azurerm_lb.crm_app_lb]
  name       = "backend-pool-1"
  loadbalancer_id = azurerm_lb.crm_app_lb.id
}
resource "azurerm_network_interface_backend_address_pool_association" "crm_app_nic_association" {
  depends_on = [azurerm_resource_group.crm_rg,azurerm_lb.crm_app_lb, azurerm_network_interface.crm_app_nic, azurerm_lb_backend_address_pool.backend_pool_1]
  network_interface_id    = azurerm_network_interface.crm_app_nic.id
  ip_configuration_name   = "crm-app-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool_1.id
}
resource "azurerm_lb_probe" "health_probe_1" {
  depends_on = [azurerm_resource_group.crm_rg,azurerm_lb.crm_app_lb, azurerm_network_interface.crm_app_nic, azurerm_lb_backend_address_pool.backend_pool_1]
  loadbalancer_id = azurerm_lb.crm_app_lb.id
  name            = "crm-health-probe-1"
  protocol        = "Http"
  port            = 2000
  request_path    = "/health"
  interval_in_seconds = 5
}
resource "azurerm_lb_rule" "lb_rule_1" {
  depends_on = [azurerm_resource_group.crm_rg,azurerm_lb.crm_app_lb, azurerm_network_interface.crm_app_nic, azurerm_lb_backend_address_pool.backend_pool_1]
  name                           = "loadbalancing-rule-1"
  loadbalancer_id                = azurerm_lb.crm_app_lb.id
  frontend_ip_configuration_name = "frontend-ip-1"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool_1.id]
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 2000
  probe_id                       = azurerm_lb_probe.health_probe_1.id
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
  enable_tcp_reset               = false
}
