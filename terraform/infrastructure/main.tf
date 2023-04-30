# ---------------------------------------------------------------------------------------------------------------------
# AWS PROVIDER FOR TF CLOUD
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    # Setting variables in the backend section isn't possible as of now, see https://github.com/hashicorp/terraform/issues/13022
    bucket = "tf-backend-state-magic-cloud-bootstrap"
    encrypt = true
    dynamodb_table = "tf-backend-lock-magic-cloud-bootstrap"
    key = "terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# Shared CI/CD infrastructure
module "cicd" {
  source = "./modules/cicd"
  project = var.project
  stack = var.stack
  aws_region = var.aws_region
  image_repo_name = var.image_repo_name
  source_repo_branch = var.source_repo_branch
  source_repo_name = var.source_repo_name
  family = var.family
  ecs_cluster_name_dev = module.compute-dev.ecs_cluster_name
  ecs_service_name_dev = module.compute-dev.ecs_service_name
  codedeploy_application_name = module.compute-prod.codedeploy_app_name
  codedeploy_deployment_group_name = module.compute-prod.codedeploy_deployment_group_name
}

# DEV stage
module "network-dev" {
  source = "./modules/network-dev"
  stage = "dev"
  project = var.project
  stack = var.stack
  az_count = var.az_count_dev
  vpc_cidr = var.vpc_cidr_dev
}
module "compute-dev" {
  source = "./modules/compute-dev"
  stage = "dev"
  depends_on = [module.network-dev.alb_security_group_ids]
  project = var.project
  stack = var.stack
  aws_region = var.aws_region
  image_repo_url = module.cicd.image_repo_url
  fargate-task-service-role = var.fargate-task-service-role-dev
  aws_alb_trgp_id = module.network-dev.alb_target_group_id
  aws_private_subnet_ids = module.network-dev.vpc_private_subnet_ids
  alb_security_group_ids = module.network-dev.alb_security_group_ids
  vpc_main_id = module.network-dev.vpc_main_id
  cw_log_group = "${var.project}-dev"
}

module "rds-dev" {
  source = "./modules/rds-dev"
  stage = "dev"
  depends_on = [module.network-dev.alb_security_group_ids]
  project = var.project
  stack = var.stack
  aws_region = var.aws_region
  aws_private_subnet_ids = module.network-dev.vpc_private_subnet_ids
  ecs_task_security_group_id = module.compute-dev.ecs_task_security_group_id
  vpc_main_id = module.network-dev.vpc_main_id
  cw_log_group = "${var.project}-dev"
}


module "redis-dev" {
  source = "./modules/redis-dev"

  cluster_id         = "cloud-bootstrap-dev"
  engine_version     = "6.2"
  instance_type      = "cache.t3.micro"
  maintenance_window = "sun:05:00-sun:06:00"
  parameter_group_name = "default.redis6.x"
  vpc_id             = module.network-dev.vpc_main_id
  private_subnet_ids = module.network-dev.vpc_private_subnet_ids
  ecs_task_security_group_id = module.compute-dev.ecs_task_security_group_id

  tag_name          = "cloud-bootstrap-dev"
  tag_team          = "cloud-bootstrap-team"
  tag_contact-email = "poh@basicit.co.kr"
  tag_application   = "cloud-bootstrap"
  tag_environment   = "dev"
  tag_customer      = "cloud-bootstrap"
}

# PROD stage
module "network-prod" {
  source = "./modules/network-prod"
  stage = "prod"
  project = var.project
  stack = var.stack
  az_count = var.az_count_prod
  vpc_cidr = var.vpc_cidr_prod
}
module "compute-prod" {
  source = "./modules/compute-prod"
  stage = "prod"
  depends_on = [module.network-prod.alb_security_group_ids]
  project = var.project
  stack = var.stack
  aws_region = var.aws_region
  image_repo_url = module.cicd.image_repo_url
  vpc_main_id = module.network-prod.vpc_main_id
  cw_log_group = "${var.project}-prod"
  fargate-task-service-role = var.fargate-task-service-role-prod
  aws_alb_listener_arn = module.network-prod.alb_listener_arn
  aws_alb_security_group_ids = module.network-prod.alb_security_group_ids
  aws_alb_trgp_blue_id = module.network-prod.alb_target_group_blue_id
  aws_alb_trgp_blue_name = module.network-prod.alb_target_group_blue_name
  aws_alb_trgp_green_id = module.network-prod.alb_target_group_green_id
  aws_alb_trgp_green_name = module.network-prod.alb_target_group_green_name
  aws_private_subnet_ids = module.network-prod.vpc_private_subnet_ids
}

module "rds-prod" {
  source = "./modules/rds-prod"
  stage = "prod"
  depends_on = [module.network-prod.alb_security_group_ids]
  project = var.project
  stack = var.stack
  aws_region = var.aws_region
  aws_private_subnet_ids = module.network-prod.vpc_private_subnet_ids
  ecs_task_security_group_id = module.compute-prod.ecs_task_security_group_id
  vpc_main_id = module.network-prod.vpc_main_id
  cw_log_group = "${var.project}-prod"
}

module "redis-prod" {
  source = "./modules/redis-prod"

  cluster_id         = "myteam-myapp-prod"
  engine_version     = "6.2"
  instance_type      = "cache.t3.micro"
  maintenance_window = "sun:05:00-sun:06:00"
  parameter_group_name = "default.redis6.x"
  vpc_id             = module.network-prod.vpc_main_id
  private_subnet_ids = module.network-prod.vpc_private_subnet_ids

  tag_name          = "cloud-bootstrap-dev"
  tag_team          = "cloud-bootstrap-team"
  tag_contact-email = "poh@basicit.co.kr"
  tag_application   = "cloud-bootstrap"
  tag_environment   = "prod"
  tag_customer      = "cloud-bootstrap"
}

output "source_repo_clone_url_http" {
  value = module.cicd.source_repo_clone_url_http
}

output "ecs_task_execution_role_arn_dev" {
  value = module.compute-dev.ecs_task_execution_role_arn
}

output "ecs_task_execution_role_arn_prod" {
  value = module.compute-prod.ecs_task_execution_role_arn
}

output "alb_address_dev" {
  value = module.network-dev.alb_address
}

output "alb_address_prod" {
  value = module.network-prod.alb_address
}
