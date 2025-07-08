# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "librechat-cluster"
}

# IAM roles for ECS task
resource "aws_iam_role" "task_exec" {
  name               = "librechat_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM role for task (application) if needed
resource "aws_iam_role" "task_role" {
  name               = "librechat_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Task definition
resource "aws_ecs_task_definition" "librechat" {
  family                   = "librechat"
  cpu                      = "1024"   # 1 vCPU
  memory                   = "2048"  # 2 GB RAM (above free tier)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "librechat"
      image     = var.librechat_image
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = var.librechat_container_port
          hostPort      = var.librechat_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "OPENAI_API_KEY", value = var.openai_api_key },
        { name = "ANTHROPIC_API_KEY", value = var.claude_api_key },
        { name = "CREDS_KEY", value = var.creds_key },
        { name = "CREDS_IV", value = var.creds_iv },
        { name = "MONGO_URI", value = "mongodb://${var.documentdb_master_username}:${var.documentdb_master_password}@${aws_docdb_cluster.librechat.endpoint}:27017/librechat?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-1" },
        { name = "EMAIL_SMTP_HOST", value = var.smtp_host },
        { name = "EMAIL_SMTP_PORT", value = tostring(var.smtp_port) },
        { name = "EMAIL_SMTP_USERNAME", value = var.smtp_username },
        { name = "EMAIL_SMTP_PASSWORD", value = var.smtp_password },
        { name = "EMAIL_SMTP_SECURE", value = var.smtp_tls ? "true" : "false" },
        { name = "DISABLE_SOCIAL_LOGIN", value = "true" },
        { name = "ALLOW_SIGNUP", value = "false" },
        { name = "NODE_ENV", value = "production" },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "JWT_REFRESH_SECRET", value = var.jwt_refresh_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.librechat.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "librechat"
        }
      }
      # Disables search engine indexing via Robots header
      extraHosts = []
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "librechat" {
  name            = "librechat-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.librechat.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets         = data.aws_subnets.public.ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.librechat.arn
    container_name   = "librechat"
    container_port   = var.librechat_container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# CloudWatch Logs group for LibreChat
resource "aws_cloudwatch_log_group" "librechat" {
  name              = "/ecs/librechat"
  retention_in_days = 30
} 