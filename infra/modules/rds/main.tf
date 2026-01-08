// DATABASE SUBNET GROUP //

resource "aws_db_subnet_group" "db_sg" {
  name = "${var.name}_db_subnet_group"
  subnet_ids = var.private_subnet_ids
}


// LOG GROUP FOR RDS //

resource "aws_cloudwatch_log_group" "rds_error_log" {
  name              = "/aws/rds/instance/${var.db_identifier}/error"
  retention_in_days = 7 
}

resource "aws_cloudwatch_log_group" "rds_slowquery_log" {
  name              = "/aws/rds/instance/${var.db_identifier}/slowquery"
  retention_in_days = 7
}

// CUSTOM PARAMETER GROUP FOR TUNING DATABASE // 

resource "aws_db_parameter_group" "mysql_pg" {
  name   = "portfolio-mysql-pg"
  family = "mysql8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }
}

// DATABASE INSTANCE //
resource "aws_db_instance" "ecs_app_db" {
  identifier                  = var.db_identifier
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.db_sg.name
  vpc_security_group_ids      = [aws_security_group.database_sg.id]
  backup_retention_period     = var.backup_retention_period
  maintenance_window          = var.maintenance_window
  multi_az                    = var.multi_az
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  publicly_accessible         = var.publicly_accessible

  parameter_group_name        = aws_db_parameter_group.mysql_pg.name

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  depends_on = [
    aws_cloudwatch_log_group.rds_error_log,
    aws_cloudwatch_log_group.rds_slowquery_log
  ]

  tags = {
    Name = "ecs database"
  }
}

// RDS CPU Utilization Alarm //

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "rds-cpu-high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"

  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecs_app_db.id
  }

  alarm_actions = [aws_sns_topic.sns_rds_alert.arn]
}

// RDS Database Connections Alarm //

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "rds-connections-high"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"

  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecs_app_db.id
  }

  alarm_actions = [aws_sns_topic.sns_rds_alert.arn]
}

// RDS Free Storage Space Alarm //

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "rds-free-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"

  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10737418240 # 10 GB
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecs_app_db.id
  }

  alarm_actions = [aws_sns_topic.sns_rds_alert.arn]
}

// RDS RAM LOW WARNING //

resource "aws_cloudwatch_metric_alarm" "database_memory_low" {
  alarm_name          = "rds-low-memory-warning"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "100000000"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecs_app_db.id
  }

  alarm_actions = [aws_sns_topic.sns_rds_alert.arn]
}

// RDS Read Latency Alarm // 

resource "aws_cloudwatch_metric_alarm" "rds_read_latency_high" {
  alarm_name          = "rds-read-latency-high"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"

  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0.1
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecs_app_db.id
  }

  alarm_actions = [aws_sns_topic.sns_rds_alert.arn]
}

// SNS TOPIC //

resource "aws_sns_topic" "sns_rds_alert" {
  name = "sns_rds_alert"  
}

resource "aws_sns_topic_subscription" "sns_rds_alert_sub" {
  topic_arn = aws_sns_topic.sns_rds_alert.arn
  protocol = "email"
  endpoint = "rizkytripamungkas9@gmail.com"
}

// DATABASE SECURITY GROUP //

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "database security group"
  vpc_id      = var.vpc_id

  ingress  {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [
    var.ecs_sg_id, 
    var.bastion_sg_id
    ]
    description     = "allow traffic from bastion and ecs container"
  }
}

