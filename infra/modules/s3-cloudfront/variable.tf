variable "name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "cloudfront_price_class" {
  type = string
}

variable "acm_cloudfront_certificate_arn" {
  type = string
}

variable "web_acl_arn" {
  type = string
}
