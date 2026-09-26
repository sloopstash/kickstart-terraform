output "aks_ct_fqdn" {
 depends_on = [azurerm_kubernetes_cluster.aks_ct]
 value = azurerm_kubernetes_cluster.aks_ct.fqdn
}
