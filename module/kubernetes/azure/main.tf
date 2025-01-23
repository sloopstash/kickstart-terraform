provider "azurerm" {
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}

resource "azurerm_resource_group" "kubernetes_rg" {
  name = "kubernetes-rg"
  location = "Central India"
  tags = {
    Name = "kubernetes-rg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_virtual_network" "kubernetes_vnet" {
  depends_on = [azurerm_resource_group.kubernetes_rg]
  name = "kubernetes-vnet"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  location = azurerm_resource_group.kubernetes_rg.location
  address_space = [var.environment == "prd" ? "11.11.0.0/16" : "12.11.0.0/16"]
  encryption {
    enforcement = "AllowUnencrypted"
  }
  tags = {
    Name = "kubernetes-vnet"
    Environment = var.environment
    Stack = "kubernetes"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_subnet" "kubernetes_vnet_bastion_sn_1" {
  depends_on = [
    azurerm_resource_group.kubernetes_rg,
    azurerm_virtual_network.kubernetes_vnet
  ]
  name = "kubernetes-vnet-bastion-sn-1"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  virtual_network_name = azurerm_virtual_network.kubernetes_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.11.1.0/24" : "12.11.1.0/24"]
}
resource "azurerm_subnet" "kubernetes_vnet_bastion_sn_2" {
  depends_on = [
    azurerm_resource_group.kubernetes_rg,
    azurerm_virtual_network.kubernetes_vnet
  ]
  name = "kubernetes-vnet-bastion-sn-2"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  virtual_network_name = azurerm_virtual_network.kubernetes_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.11.2.0/24" : "12.11.2.0/24"]
}
resource "azurerm_subnet" "kubernetes_vnet_aks_nd_sn_1" {
  depends_on = [
    azurerm_resource_group.kubernetes_rg,
    azurerm_virtual_network.kubernetes_vnet
  ]
  name = "kubernetes-vnet-aks-nd-sn-1"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  virtual_network_name = azurerm_virtual_network.kubernetes_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.11.9.0/24" : "12.11.9.0/24"]
}
resource "azurerm_subnet" "kubernetes_vnet_aks_nd_sn_2" {
  depends_on = [
    azurerm_resource_group.kubernetes_rg,
    azurerm_virtual_network.kubernetes_vnet
  ]
  name = "kubernetes-vnet-aks-nd-sn-2"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  virtual_network_name = azurerm_virtual_network.kubernetes_vnet.name
  address_prefixes = [var.environment == "prd" ? "11.11.10.0/24" : "12.11.10.0/24"]
}
resource "azurerm_network_security_group" "kubernetes_bastion_nsg" {
  depends_on = [azurerm_resource_group.kubernetes_rg]
  name = "kubernetes-bastion-nsg"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  location = azurerm_resource_group.kubernetes_rg.location
  security_rule {
    name = "AllowAnySSHInbound"
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
    Name = "kubernetes-bastion-nsg"
    Environment = var.environment
    Stack = "kubernetes"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_kubernetes_cluster" "kubernetes_aks_ct" {
  depends_on = [
    azurerm_resource_group.kubernetes_rg,
    azurerm_subnet.kubernetes_vnet_aks_nd_sn_1,
    azurerm_subnet.kubernetes_vnet_aks_nd_sn_2
  ]
  name = "kubernetes-aks-ct"
  resource_group_name = azurerm_resource_group.kubernetes_rg.name
  location = azurerm_resource_group.kubernetes_rg.location
  kubernetes_version = "1.28.15"
  sku_tier = "Free"
  identity {
    type = "SystemAssigned"
  }
  open_service_mesh_enabled = false
  private_cluster_enabled = false
  dns_prefix = "kubernetes-aks-ct-api-endpoint"
  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/0"]
  }
  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
    ip_versions = ["IPv4"]
    load_balancer_sku = "standard"
  }
  node_resource_group = "kubernetes-aks-ct-rg"
  default_node_pool {
    name = "nodepool1"
    vm_size = "Standard_D2as_v4"
    type = "VirtualMachineScaleSets"
    os_sku = "AzureLinux"
    vnet_subnet_id = azurerm_subnet.kubernetes_vnet_aks_nd_sn_1.id
    node_public_ip_enabled = false
    ultra_ssd_enabled = false
    host_encryption_enabled = false
    orchestrator_version = "1.28.15"
    workload_runtime = "OCIContainer"
    auto_scaling_enabled = true
    max_count = 1
    min_count = 1
    node_count = 1
    max_pods = 50
  }
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel = "NodeImage"
  maintenance_window {
    allowed {
      day = "Sunday"
      hours = [1,2]
    }
  }
  role_based_access_control_enabled = true
  azure_policy_enabled = false
  image_cleaner_enabled = false
  oidc_issuer_enabled = false
  run_command_enabled = true
  tags = {
    Name = "kubernetes-aks-ct"
    Environment = var.environment
    Stack = "kubernetes"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
