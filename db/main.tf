resource "aws_security_group" "db_sg" {
  name_prefix = "${var.name}-sg"
  vpc_id      = var.vpc_id
}

resource "random_password" "additional_db_passwords" {
  count   = var.random_password ? 1 : 0
  length  = 16
  special = false
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "rds-enhanced-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_db_instance" "db" {
  db_name             = var.name
  instance_class      = var.instance_class
  engine              = var.engine
  engine_version      = var.engine_version
  allocated_storage   = var.storage
  username            = var.user
  password            = var.random_password ? random_password.additional_db_passwords[0].result : var.password
  skip_final_snapshot = true

  multi_az = var.multi_az

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = var.subnet_group_name

  # Cloudwatch logs
  enabled_cloudwatch_logs_exports = var.types_cloudwatch_logs_exports

  # Enhanced monitoring
  monitoring_interval = 30
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Performance insights
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
}
