data "aws_route53_zone" "main_route53" {
  name         = "rizkyproject.site"
  private_zone = false
}


resource "aws_route53_record" "cloudfront_www" {
  zone_id   = data.aws_route53_zone.main_route53.zone_id
  name      = "test.rizkyproject.site"
  type      = "A"

  alias {
    name    = var.cloudfront_domain_name
    zone_id = var.cloudfront_zone_id
    evaluate_target_health = false
  }  
}


resource "aws_route53_record" "alb_backend" {
  zone_id = data.aws_route53_zone.main_route53.zone_id
  name    = "api.rizkyproject.site"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}
