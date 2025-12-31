variable "name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "alb_target_group_name" {
  type    = string
  default = "ecs-target-group"
}

variable "target_group_port" {
  type    = number
  default = 3000
}

variable "target_group_protocol" {
  type    = string
  default = "HTTP"
}

variable "acm_alb_certificate_arn" {
  type = string
  
}