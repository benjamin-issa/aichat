resource "aws_wafv2_web_acl" "librechat" {
  name        = "librechat-waf"
  description = "WAF protecting LibreChat ALB"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    metric_name = "librechatWAF"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
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
      metric_name                = "CommonRuleSet"
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      metric_name                = "KnownBadInputs"
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
    }
  }
}

# Associate WAF with the ALB
resource "aws_wafv2_web_acl_association" "librechat" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.librechat.arn
} 