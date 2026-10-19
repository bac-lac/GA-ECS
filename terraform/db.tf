resource "aws_db_subnet_group" "data" {
  name       = "ga-db-subnet-group-${var.ENV}"
  subnet_ids = data.aws_subnets.data.ids
}

resource "aws_db_instance" "ga_mysql" {
  allocated_storage                   = var.DB_ALLOCATED_STORAGE
  apply_immediately                   = true
  auto_minor_version_upgrade          = true
  backup_retention_period             = 35
  backup_window                       = var.DB_BACKUP_WINDOW
  copy_tags_to_snapshot               = true
  db_subnet_group_name                = aws_db_subnet_group.data.name
  deletion_protection                 = true
  enabled_cloudwatch_logs_exports     = ["audit", "general", "error", "slowquery"]
  engine                              = "mysql"
  engine_version                      = var.DB_ENGINE_VERSION
  iam_database_authentication_enabled = true
  identifier                          = "ga-db-${var.ENV}"
  instance_class                      = var.DB_INSTANCE_CLASS
  maintenance_window                  = var.DB_MAINTENANCE_WINDOW
  monitoring_interval                 = 5
  monitoring_role_arn                 = aws_iam_role.ga_rds_monitoring_role.arn
  password                            = var.ADMIN_DB_PASSWORD
  performance_insights_enabled        = true
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  storage_type                        = "gp3"  
  username                            = var.ADMIN_DB_USERNAME
  vpc_security_group_ids              = [data.aws_security_group.data.id]
}