resource "aws_wafv2_web_acl" "ecs-app-waf" {
  name        = "managed-rule-ecs-app-waf"
  description = "WAF for CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # 1. AWS Managed Rule: Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetrics"
      sampled_requests_enabled   = true
    }
  }

  # 2. AWS Managed Rule: IP Reputation
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPReputationMetrics"
      sampled_requests_enabled   = true
    }
  }

  # 3. Custom Rule: Rate Limit dengan CAPTCHA
  rule {
    name     = "IPRateLimit"
    priority = 2

    action {
      captcha {} 
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetrics"
      sampled_requests_enabled   = true
    }
  }

  # Visibility config utama untuk Web ACL
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainMetrics"
    sampled_requests_enabled   = true
  }
}