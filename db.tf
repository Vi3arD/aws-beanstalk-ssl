module "main_db" {
  source = "./db"

  name = var.main_db_name
  engine = var.main_db_engine
  engine_version = var.main_db_engine_version
  instance_class = var.main_db_instance_class
  storage = var.main_db_storage
  user = var.main_db_user
  password = var.main_db_password
  random_password = var.main_db_random_password

  vpc_id = aws_vpc.main.id
  subnet_group_name = aws_db_subnet_group.this.name
  multi_az = var.main_db_multi_az

  types_cloudwatch_logs_exports = var.main_db_types_cloudwatch_logs_exports

  performance_insights_enabled = var.main_db_performance_insights_enabled
  performance_insights_retention_period = var.main_db_performance_insights_retention_period  
}

resource "aws_security_group_rule" "main_db" {
  type              = "ingress"
  security_group_id = module.main_db.sg_id

  from_port         = 0
  to_port           = module.main_db.port
  protocol          = "tcp"
  source_security_group_id = aws_security_group.instance.id
}

