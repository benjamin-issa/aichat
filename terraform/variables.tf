variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Fully-qualified domain name that points to the load balancer. Must already be delegated via Route53 or external DNS."
  type        = string
}

variable "acm_certificate_arn" {
  description = "(Optional) Existing ACM certificate ARN to use for the ALB listener. Leave blank to request a new certificate."
  type        = string
  default     = ""
}

# LibreChat Secrets & Auth
variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "claude_api_key" {
  description = "Claude (Anthropic) API key"
  type        = string
  sensitive   = true
}

variable "creds_key" {
  description = "Encryption key for LibreChat credentials"
  type        = string
  sensitive   = true
}

variable "creds_iv" {
  description = "Encryption IV for LibreChat credentials"
  type        = string
  sensitive   = true
}

# Email / SMTP configuration
variable "smtp_host" {
  description = "SMTP host (SES endpoint in another account)"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
}

variable "smtp_tls" {
  description = "Whether to enable TLS for SMTP"
  type        = bool
  default     = true
}

# DocumentDB credentials
variable "documentdb_master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "librechat"
}

variable "documentdb_master_password" {
  description = "Master password for DocumentDB"
  type        = string
  sensitive   = true
}

variable "librechat_image" {
  description = "Docker image for LibreChat"
  type        = string
  default     = "ghcr.io/danny-avila/librechat:latest"
}

variable "librechat_container_port" {
  description = "Port the LibreChat container listens on"
  type        = number
  default     = 3000
}

variable "jwt_secret" {
  description = "Secret key for JWT authentication"
  type        = string
  sensitive   = true
}

variable "jwt_refresh_secret" {
  description = "Secret key for JWT refresh tokens"
  type        = string
  sensitive   = true
} 