output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "librechat_url" {
  description = "HTTPS URL for LibreChat"
  value       = "https://${var.domain_name}"
} 