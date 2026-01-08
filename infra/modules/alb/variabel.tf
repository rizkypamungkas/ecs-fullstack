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
}

variable "target_group_port" {
  type    = number
}

variable "target_group_protocol" {
  type    = string
}

variable "acm_alb_certificate_arn" {
  type = string
  
}