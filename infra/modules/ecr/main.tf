// CREATE REPO // 

resource "aws_ecr_repository" "app_repository" {
  name = var.repo_name
  
  image_tag_mutability = "IMMUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

// REPO POLICY //

resource "aws_ecr_lifecycle_policy" "demo_ecr_policy" {
  repository = aws_ecr_repository.app_repository.name

    policy = jsonencode({
      rules = [{
        rulePriority = 1
        description  = "Expire untagged images after 30 days"
        selection = {
          tagStatus    = "untagged"
          countType    = "sinceImagePushed"
          countUnit    = "days"
          countNumber  = 30
        }
        action = {
          type = "expire"
        }
      }]
    })
  }