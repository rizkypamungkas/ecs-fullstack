output "alb_tg_arn" {
  value = aws_lb_target_group.ecs_tg.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_dns_name" {
  value = aws_alb.alb_ecs.dns_name
}

output "alb_zone_id" {
  value = aws_alb.alb_ecs.zone_id 
}

output "aws_alb_arn_suffix" {
  value = aws_alb.alb_ecs.arn_suffix
}