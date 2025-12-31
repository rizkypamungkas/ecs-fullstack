variable "name" {
  type = string
}

variable "github_repo" {
  type        = string
  description = "GitHub repo, example: username/repo"
}

variable "aws_region" {
  type = string
}

variable "frontend_bucket_arn" {
  type = string
}

variable "cloudfront_distribution_arn" {
  type = string
}

variable "secret_arns" {
  type        = list(string)
  default     = []
  description = "Secrets Manager ARNs accessed by ECS task"
}

variable "ssm_parameter_arns" {
  type        = list(string)
  default     = []
  description = "SSM Parameter ARNs accessed by ECS task"
}
