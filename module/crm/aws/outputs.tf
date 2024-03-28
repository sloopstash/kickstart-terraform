output "crm_cloud_front_app_stt_dst_domain" {
  depends_on = [aws_cloudfront_distribution.crm_cloud_front_app_stt_dst]
  value = aws_cloudfront_distribution.crm_cloud_front_app_stt_dst.domain_name
}
