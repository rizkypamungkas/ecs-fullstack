variable "name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "alb_dns_name" {
  description = "ALB DNS name for API backend origin"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe only (cheapest)
}

variable "acm_cloudfront_certificate_arn" {
  description = "ACM certificate ARN for custom domain (optional, leave empty for CloudFront default)"
  type        = string
}