# Enable GuardDuty with ECS runtime monitoring
resource "aws_guardduty_detector" "this" {
  enable = true
}

# Enable ECS runtime monitoring feature on the detector
resource "aws_guardduty_detector_feature" "ecs_runtime" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}

# SNS Topic for notifications
resource "aws_sns_topic" "guardduty" {
  name = "guardduty-findings-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.guardduty.arn
  protocol  = "email"
  endpoint  = "benjamin.issa+aichat@protonmail.com"
}

# EventBridge rule to send GuardDuty findings to SNS
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name          = "guardduty-findings-rule"
  description   = "Forward GuardDuty findings to SNS"
  event_pattern = jsonencode({
    "source"      : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"],
    "detail" : {
      "severity" : [{"numeric" : [">=", 0]}]
    }
  })
  depends_on = [aws_guardduty_detector.this]
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_sns_topic.guardduty.arn  # placeholder
  principal     = "events.amazonaws.com"
}

# VPC endpoint for GuardDuty data plane (required for ECS runtime monitoring)
resource "aws_vpc_endpoint" "guardduty_data" {
  vpc_id       = data.aws_vpc.default.id
  service_name = "com.amazonaws.${var.aws_region}.guardduty-data"
  vpc_endpoint_type = "Interface"
  subnet_ids   = data.aws_subnets.public.ids
  security_group_ids = [aws_security_group.ecs_service.id]
  private_dns_enabled = true
} 