# VPC + subnets 
module "vpc" {
  source          = "./modules/vpc"
  name            = var.project_name
  vpc_cidr        = var.vpc_cidr
  public_subnet   = var.public_subnet
  private_subnet  = var.private_subnet
}

# Bastion to SSH into private network
module "bastion" {
  source          = "./modules/bastion"
  vpc_id          = module.vpc.vpc_id
  public_subnet   = module.vpc.public_subnet_ids
  instance_type   = var.instance_type
  key_name        = var.key_name
}

# AWS repo to store container images
module "ecr" {
  source          = "./modules/ecr"
  repo_name       = var.repo_name
}

# Public-facing load balancer
module "alb" {
  source                  = "./modules/alb"
  name                    = var.project_name
  vpc_id                  = module.vpc.vpc_id
  alb_target_group_name   = var.alb_target_group_name
  target_group_port       = var.target_group_port
  target_group_protocol   = var.target_group_protocol
  public_subnet_ids       = module.vpc.public_subnet_ids
  acm_alb_certificate_arn = module.acm.acm_alb_certificate_arn
}

# ECS Fargate runs app containers
module "ecs_fargate" {
  source                  = "./modules/ecs_fargate"
  name                    = var.project_name
  cluster_name            = var.cluster_name

  # AWS context
  aws_region              = var.region

  # DB connection env vars
  db_name                 = module.rds.db_name
  db_username             = module.rds.db_username
  db_host                 = module.rds.db_endpoint
  db_port                 = module.rds.db_port
  db_password_secret_arn  = module.rds.db_password_secret_arn

  # Container settings
  container_name          = var.container_name
  container_port          = var.container_port
  cpu                     = var.cpu
  memory                  = var.memory

  # Image info
  ecr_repo_name           = var.ecr_repo_name

  # Networking + LB integration
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  desired_count           = var.desired_count
  alb_sg_id               = module.alb.alb_sg_id
  alb_tg_arn              = module.alb.alb_tg_arn
}

# RDS database in private subnets
module "rds" {
  source                  = "./modules/rds"
  name                    = var.project_name
  db_identifier           = var.db_identifier

  # Engine & instance config
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username

  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage

  # Networking + access control
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  publicly_accessible     = var.publicly_accessible
  bastion_sg_id           = module.bastion.bastion_sg_id
  ecs_sg_id               = module.ecs_fargate.ecs_sg_id

  # HA + maintenance
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  maintenance_window      = var.maintenance_window

  # Deletion behavior
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection
}

# WAF
module "waf" {
  source    = "./modules/waf"
  providers = {
    aws.us_east_1 = aws.us_east_1 
  }
}

# S3 bucket for frontend + CloudFront 
module "s3-cloudfront" {
  source                          = "./modules/s3-cloudfront"
  name                            = var.project_name
  alb_dns_name                    = module.alb.alb_dns_name
  acm_cloudfront_certificate_arn  = module.acm.acm_cloudfront_certificate_arn
  depends_on                      = [ module.acm ]
  web_acl_arn                     = module.waf.web_acl_arn
  cloudfront_price_class          = var.cloudfront_price_class
}

# ACM certs 
module "acm" {
  providers       = { 
    aws.us_east_1 = aws.us_east_1 
    }
  source          = "./modules/acm"
  name            = var.project_name
  route53_zone_id = module.route53.route53_zone_id
}

# DNS records pointing to CloudFront + ALB
module "route53" {
  source                  = "./modules/route53"
  cloudfront_zone_id      = module.s3-cloudfront.cloudfront_zone_id
  cloudfront_domain_name  = module.s3-cloudfront.cloudfront_domain_name
  alb_dns_name            = module.alb.alb_dns_name
  alb_zone_id             = module.alb.alb_zone_id
}

# Logs, alarms, dashboards, etc.
module "observability" {
  source               = "./modules/observability"
  db_name_id           = module.rds.db_name_id
  aws_ecs_cluster_name = module.ecs_fargate.ecs_cluster_name
  aws_ecs_service_name = module.ecs_fargate.ecs_service_name
  aws_alb_arn_suffix   = module.alb.aws_alb_arn_suffix
}

# IAM roles for CI/CD deploy + S3/CloudFront access
module "iam-role" {
  source                      = "./modules/iam-role"
  name                        = var.project_name
  aws_region                  = var.aws_region
  github_repo                 = var.github_repo
  frontend_bucket_arn         = module.s3-cloudfront.s3_bucket_arn
  cloudfront_distribution_arn = module.s3-cloudfront.cloudfront_distribution_arn
}
