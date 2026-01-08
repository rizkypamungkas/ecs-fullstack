resource "aws_cloudwatch_dashboard" "full-dashboard" {
  dashboard_name = "ecs-alb-rds-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0, y = 0, width = 12, height = 6,
        properties = {
          title = "ECS CPU Utilization",
          metrics = [
            ["AWS/ECS", "CPUUtilization",
             "ClusterName", var.aws_ecs_cluster_name,
             "ServiceName", var.aws_ecs_service_name]
          ],
          period = 60,
          stat   = "Average",
          region = "ap-southeast-1"
        }
      },
      {
        type = "metric",
        x = 12, y = 0, width = 12, height = 6,
        properties = {
          title = "ALB Target 5XX",
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
             "LoadBalancer", var.aws_alb_arn_suffix]
          ],
          period = 60,
          stat   = "Sum",
          region = "ap-southeast-1"
        }
      },
      {
        type = "metric",
        x = 0, y = 6, width = 12, height = 6,
        properties = {
          title = "RDS Connections",
          metrics = [
            ["AWS/RDS", "DatabaseConnections",
             "DBInstanceIdentifier", var.db_name_id]
          ],
          period = 60,
          stat   = "Average",
          region = "ap-southeast-1"
        }
      }
    ]
  })
}
