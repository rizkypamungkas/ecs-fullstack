output "acm_cloudfront_certificate_arn" {
  value = aws_acm_certificate.cloudfront_cert.arn
}

output "acm_alb_certificate_arn" {
  value = aws_acm_certificate.alb_backend_cert.arn
}
