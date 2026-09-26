output "rg_name" {
  depends_on = [azurerm_resource_group.rg]
  value = azurerm_resource_group.rg.name
}
output "rg_location" {
  depends_on = [azurerm_resource_group.rg]
  value = azurerm_resource_group.rg.location
}
output "vnet_name" {
  depends_on = [azurerm_virtual_network.vnet]
  value = azurerm_virtual_network.vnet.name
}
output "ng_id" {
  depends_on = [azurerm_nat_gateway.ng]
  value = azurerm_nat_gateway.ng.id
}
