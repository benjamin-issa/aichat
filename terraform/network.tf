# ACM certificate (optional creation if not provided by caller)
resource "aws_acm_certificate" "this" {
  count              = var.acm_certificate_arn == "" ? 1 : 0
  domain_name        = var.domain_name
  validation_method  = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "librechat-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
}

# Target group for ECS service
resource "aws_lb_target_group" "librechat" {
  name        = "tg-librechat"
  port        = var.librechat_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    path                = "/api/auth/status"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener for HTTPS (443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.this[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.librechat.arn
  }
}

# Listener for HTTP (80) -> redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
} 