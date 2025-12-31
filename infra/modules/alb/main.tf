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
