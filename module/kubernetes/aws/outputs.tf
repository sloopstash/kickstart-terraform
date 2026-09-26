output "eks_ct_endpoint" {
  depends_on = [aws_eks_cluster.eks_ct]
  value = aws_eks_cluster.eks_ct.endpoint
}
