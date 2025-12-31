// CREATE CERTIFICATE REQUEST FOR CLOUDFRONT //

resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1
  domain_name       = "test.rizkyproject.site"
  validation_method = "DNS"

  tags = {
    name = "${var.name}-cloudfront-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// DNS VALIDATION RECORD FOR CLOUDFRONT CERT //

resource "aws_route53_record" "cloudfront_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}


// VALIDATE CLOUDFRONT CERTIFICATE //

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_cert_validation_record : record.fqdn]
  
  timeouts {
    create = "10m"
  }
}


// ACM CERTIFICATE FOR ALB BACKEND //

resource "aws_acm_certificate" "alb_backend_cert" {
  domain_name       = "api.rizkyproject.site"
  validation_method = "DNS"

  tags = {
    name = "${var.name}-alb-backend-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// CREATE DNS RECORD THAT WILL BE USED FOR CERTIFICATE VALIDATION //

resource "aws_route53_record" "alb_backend_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.alb_backend_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}


// VALIDATE ALB BACKEND CERTIFICATE //

resource "aws_acm_certificate_validation" "alb_backend_cert_validation" {
  certificate_arn         = aws_acm_certificate.alb_backend_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.alb_backend_cert_validation_record : record.fqdn]
  
  timeouts {
    create = "10m"
  }
}