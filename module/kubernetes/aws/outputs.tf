output "kubernetes_eks_ct_endpoint" {
  depends_on = [aws_eks_cluster.kubernetes_eks_ct]
  value = aws_eks_cluster.kubernetes_eks_ct.endpoint
}
