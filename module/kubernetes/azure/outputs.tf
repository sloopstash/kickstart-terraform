output "kubernetes_eks_ct_fqdn" {
  depends_on = [azurerm_kubernetes_cluster.kubernetes_aks_ct]
  value = azurerm_kubernetes_cluster.kubernetes_aks_ct.fqdn
}
