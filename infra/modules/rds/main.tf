// DATABASE SUBNET GROUP //

resource "aws_db_subnet_group" "db_sg" {
  name = "${var.name}_db_subnet_group"
  subnet_ids = var.private_subnet_ids
}


// DATABASE INSTANCE //
resource "aws_db_instance" "ecs_app_db" {
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.db_sg.name
  vpc_security_group_ids      = [aws_security_group.database_sg.id]
  backup_retention_period     = var.backup_retention_period
  maintenance_window          = var.maintenance_window
  multi_az                    = var.multi_az
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  publicly_accessible         = var.publicly_accessible

  tags = {
    name = "ecs database"
  }
}

// DATABASE SECURITY GROUP //

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "database security group"
  vpc_id      = var.vpc_id

  ingress  {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [
    var.ecs_sg_id, 
    var.bastion_sg_id
    ]
    description     = "allow traffic from bastion and ecs container"
  }
}

