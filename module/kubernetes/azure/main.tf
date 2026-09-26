provider "azurerm" {
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}

resource "azurerm_subnet" "container_s2_vnet_kubernetes_sn_1" {
  depends_on = [
    var.rg_name,
    var.vnet_name
  ]
  name = "container-s2-vnet-kubernetes-sn-1"
  resource_group_name = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes = [var.environment == "prd" ? "11.1.9.0/24" : "12.1.9.0/24"]
}
resource "azurerm_subnet" "container_s2_vnet_kubernetes_sn_2" {
  depends_on = [
    var.rg_name,
    var.vnet_name
  ]
  name = "container-s2-vnet-kubernetes-sn-2"
  resource_group_name = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes = [var.environment == "prd" ? "11.1.10.0/24" : "12.1.10.0/24"]
}
resource "azurerm_subnet_nat_gateway_association" "container_s2_vnet_kubernetes_sn_1_ng_ass" {
  depends_on = [
    azurerm_subnet.container_s2_vnet_kubernetes_sn_1,
    var.ng_id
  ]
  subnet_id = azurerm_subnet.container_s2_vnet_kubernetes_sn_1.id
  nat_gateway_id = var.ng_id
}
resource "azurerm_subnet_nat_gateway_association" "container_s2_vnet_kubernetes_sn_2_ng_ass" {
  depends_on = [
    azurerm_subnet.container_s2_vnet_kubernetes_sn_2,
    var.ng_id
  ]
  subnet_id = azurerm_subnet.container_s2_vnet_kubernetes_sn_2.id
  nat_gateway_id = var.ng_id
}
resource "azurerm_network_security_group" "container_s2_kubernetes_nsg" {
  depends_on = [
    var.rg_name,
    var.rg_location
  ]
  name = "container-s2-kubernetes-nsg"
  resource_group_name = var.rg_name
  location = var.rg_location
  tags = {
    Name = "container-s2-kubernetes-nsg"
    Environment = var.environment
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
resource "azurerm_kubernetes_cluster" "aks_ct" {
  depends_on = [
    var.rg_name,
    var.rg_location,
    azurerm_subnet.container_s2_vnet_kubernetes_sn_1,
    azurerm_subnet.container_s2_vnet_kubernetes_sn_2
  ]
  name = "aks-ct"
  resource_group_name = var.rg_name
  location = var.rg_location
  kubernetes_version = "1.36"
  sku_tier = "Free"
  identity {
    type = "SystemAssigned"
  }
  open_service_mesh_enabled = false
  private_cluster_enabled = false
  dns_prefix = "aks-ct-api-endpoint"
  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/0"]
  }
  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
    ip_versions = ["IPv4"]
    load_balancer_sku = "standard"
  }
  node_resource_group = "aks-ct-rg"
  default_node_pool {
    name = "nodepool1"
    vm_size = "Standard_D2as_v4"
    type = "VirtualMachineScaleSets"
    os_sku = "AzureLinux"
    vnet_subnet_id = azurerm_subnet.container_s2_vnet_kubernetes_sn_1.id
    node_public_ip_enabled = false
    ultra_ssd_enabled = false
    host_encryption_enabled = false
    orchestrator_version = "1.36"
    workload_runtime = "OCIContainer"
    auto_scaling_enabled = true
    max_count = 1
    min_count = 1
    node_count = 1
    max_pods = 50
  }
  node_provisioning_profile {
    mode = "Manual"
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
    Name = "aks-ct"
    Environment = var.environment
    Stack = "container-s2/kubernetes"
    Region = "centralindia"
    Organization = "sloopstash"
  }
}
