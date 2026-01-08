variable "vpc_id" {
  type = string
}

variable "name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cpu" {
  type = string
}

variable "memory" {
  type = string
}

variable "container_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "alb_sg_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string) 
}

variable "alb_tg_arn" {
  type = string
}

variable "db_password_secret_arn" {
  type        = string
  description = "Secrets Manager ARN untuk DB password"
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_port" {
  type = string
}

variable "desired_count" {
  type = number
}
