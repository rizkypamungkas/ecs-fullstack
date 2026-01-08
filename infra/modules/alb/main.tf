// APPLICATION LOAD BALANCER //

resource "aws_alb" "alb_ecs" {
  name                = "${var.name}-alb"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.alb_sg.id]
  subnets             = var.public_subnet_ids
  ip_address_type     = "ipv4"
  enable_deletion_protection = false

  tags = {
    name = "${var.name}_alb"
  } 
}

// TARGET GROUP //

resource "aws_lb_target_group" "ecs_tg" {
  name        = var.alb_target_group_name
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    port                = 3000
    path                = "/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200-399"
  }
  tags = {
    name = "${var.alb_target_group_name}_tg"
  }

  lifecycle {
    prevent_destroy = false
  }
}

// HTTP LISTENER //

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb_ecs.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_alb_certificate_arn

  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.ecs_tg.arn
  } 
}

// HTTP 5XX ALARM (ERROR SERVER) //

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "ALB-High-5XX-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60" # check every 60 seconds
  statistic           = "Sum"
  threshold           = "5" # alarm send email if error > 5
  
  dimensions = {
    LoadBalancer = aws_alb.alb_ecs.arn_suffix
  }

  alarm_actions = [aws_sns_topic.sns_alb_alert.arn] 
}

// ALB ALARM WHEN TARGETS FAIL HEALTH CHECKS (UnHealthyHostCount) //

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "ALB-Unhealthy-Hosts-Detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Deteksi jika ada task ECS yang gagal health check"

  dimensions = {
    LoadBalancer = aws_alb.alb_ecs.arn_suffix
    TargetGroup  = aws_lb_target_group.ecs_tg.arn_suffix
  }

  alarm_actions = [aws_sns_topic.sns_alb_alert.arn]
}

// SNS TOPIC //

resource "aws_sns_topic" "sns_alb_alert" {
  name = "sns_alb_alert"  
}

resource "aws_sns_topic_subscription" "sns_alb_alert_sub" {
  topic_arn = aws_sns_topic.sns_alb_alert.arn
  protocol = "email"
  endpoint = "rizkytripamungkas9@gmail.com"
}

// ALB SECURITY GROUP //

resource "aws_security_group" "alb_sg" {
  name        = "${var.name}_alb_sg"
  vpc_id      = var.vpc_id
  description = "alb security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}
