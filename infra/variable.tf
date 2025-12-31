// VPC //

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "region" {
  type = string
}

variable "public_subnet" {
  type = list(string)
}
variable "private_subnet" {
  type = list(string)
}

// BASTION //

variable "instance_type" {
  type = string
}
variable "key_name" {
  type = string
  
}

// ECR //

variable "repo_name" {
   type = string
 }

 // RDS // 

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

// ECS //

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

variable "aws_account_id" {
  type = number
}

variable "aws_region" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type = number
}

// IAM ROLE //

variable "github_repo" {
  type = string
}