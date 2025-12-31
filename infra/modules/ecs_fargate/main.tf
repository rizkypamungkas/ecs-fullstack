// ECS CLUSTER //

resource "aws_ecs_cluster" "app_cluster" {
  name = var.cluster_name
}

// IAM ROLE EXECUTION TASK //

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.cluster_name}_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach default AmazonECSTaskExecutionRolePolicy (ECR + CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra permission: Secrets Manager (needed if you inject secrets via task definition)
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.cluster_name}_execution_secrets"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "${var.db_password_secret_arn}*"
      }
    ]
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Task Role Policy: app container can access AWS services
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.cluster_name}_task_policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "events:PutEvents",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "s3:PutObject",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "${var.db_password_secret_arn}*"
      }
    ]
  })
}
// LOG GROUP //

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = 14
}

// ECS TASK DEFINITION // 

resource "aws_ecs_task_definition" "app_task" {
  family                   = var.cluster_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs]

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "535002865174.dkr.ecr.ap-southeast-1.amazonaws.com/app_repo:latest"
      essential = true
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
    
      environment = [
        {name = "DB_HOST" , value = var.db_host},
        {name = "DB_USER",  value = var.db_username},
        {name = "DB_NAME",  value = var.db_name},
        {name = "DB_PORT",  value = tostring(var.db_port)},
        {name = "PORT",     value = tostring(var.container_port)}]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_password_secret_arn}:password::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = var.container_name
        }
      }
    }
  ])
}
// ECS SERVICE //

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.cluster_name}_ecs_service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  platform_version = "LATEST"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    aws_cloudwatch_log_group.ecs
  ]
}

// CLOUDWATCH METRIC ALARM & AUTOSCALING //

resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "ecs_cpu_scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

// ECS SECURITY GROUP

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  vpc_id      = var.vpc_id
  description = "ecs"

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "allow inbound from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outbound to RDS"
  }
}
