variable "name" {
  type = string
}

variable "db_identifier" {
  type = string  
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type = number
}

variable "multi_az" {
  type = bool
}

variable "db_name" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_username" {
  type = string
}

variable "backup_retention_period" {
  type = number
}

variable "maintenance_window" {
  type = string  
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "publicly_accessible" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}