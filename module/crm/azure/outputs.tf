output "crm_bastion_vm_ip" {
  depends_on = [azurerm_linux_virtual_machine.crm_bastion_vm_1]
  value = azurerm_public_ip.crm_public_ip["bastion"].ip_address
}
output "crm_loadbalancer_frontend_ip" {
  description = "Frontend IP address of the Azure Load Balancer"
  value       = azurerm_public_ip.crm_public_ip["loadbalancer"].ip_address
}
output "cdn_endpoint_url" {
  description = "Hostname of the Azure CDN endpoint"
  value       = azurerm_cdn_endpoint.crm_cdn_endpoint.fqdn
}
