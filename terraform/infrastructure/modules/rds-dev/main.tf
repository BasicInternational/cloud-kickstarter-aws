resource "random_password" "db_admin_password" {
  length = 16
  special = true
  override_special = "_"
}

resource "aws_security_group" "rds_instance" {
  name        = "${var.environment_name}-${var.ecs_cluster_name}-rds-sg"
  description = "${var.environment_name}-${var.ecs_cluster_name}-rds-sg"
  vpc_id      = "${var.vpc_main_id}"
  tags = {
    Name      = "${var.environment_name}-${var.ecs_cluster_name}-rds-sg"
  }
}

resource "aws_security_group_rule" "mysql" {
  security_group_id        = aws_security_group.rds_instance.id
  description              = "TCP/3306 for ECS Instances"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = var.ecs_task_security_group_id
}

resource "aws_db_instance" "dev" {
  identifier             = "${var.platform_type}-${var.environment_name}-rds-instance"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.27"
  instance_class         = var.rds_instance_type
  username               = var.rds_admin_username
  password               = random_password.db_admin_password.result
  db_subnet_group_name   = var.vpc_private_subnet_group_id
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_instance.id]
  tags = {
    Name               = "${var.platform_type}-${var.environment_name}-rds-instance"
  }
}
