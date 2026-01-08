output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name 
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

