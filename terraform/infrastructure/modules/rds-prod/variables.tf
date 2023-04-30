
variable "rds_instance_type" {
  type    = string
  default = "db.t2.micro"
}

variable "platform_type" {
  type       = string
  default = "ecs"
}

variable "service_name_short" {
  type    = string
  default = "cargarage"
}

variable "environment_name" {
  type    = string
  default = "prod"
}

variable "ecs_cluster_name" {
  type    = string
  default = "ecs-cluster"
}

variable "rds_admin_username" {
  type    = string
  default = "admin"
}

variable "rds_subnet_group_name" {
  type    = string
  default = "private"
}

variable "project" {
  description = "Name of the project."
}

variable "stack" {
  description = "Name of the stack."
}

variable "stage" {}

variable "aws_region" {
  description = "The AWS region to create things in."
}

variable "cw_log_group" {
  description = "CloudWatch Log Group"
}

variable "cw_log_stream" {
  description = "CloudWatch Log Stream"
  default     = "fargate"
}


variable "aws_private_subnet_ids" {}
variable "vpc_main_id" {}
variable "ecs_task_security_group_id" {}
