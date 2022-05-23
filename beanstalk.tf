resource "random_password" "main_db_password" {
  length  = 16
  special = false
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = var.name
  description = "description"
}

data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true

  name_regex = "^64bit Amazon Linux 2 (.*) running Docker(.*)$"
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${var.name}-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.docker.name

  version_label = aws_elastic_beanstalk_application_version.latest.name
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.use_private_subnets ? aws_subnet.private[*].id : aws_subnet.public[*].id)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", aws_subnet.public[*].id)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "DBSubnets"
    value     = join(",", var.use_private_subnets ? aws_subnet.private[*].id : aws_subnet.public[*].id)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = !var.use_private_subnets
  }

  ############################################################
  # Get cert from AWS CM case
  ############################################################
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:redirectproc"
    name      = "Port"
    value     = "443"
  }

  setting {
    namespace = "aws:elbv2:listenerrule:redirect"
    name      = "HostHeaders"
    value     = join(",", var.san)
  }

  setting {
    namespace = "aws:elbv2:listenerrule:redirect"
    name      = "Process"
    value     = "redirectproc"
  }

  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "Rules"
    value     = "redirect"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = true
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.certificate.arn
  }

  ############################################################

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.key.key_name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.instance.id
  }

  
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instance_type
  }

  
  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = tostring(var.enable_spot)
  }

  dynamic "setting" {
    for_each = var.enable_spot ? [1] : []
    content {
      namespace = "aws:ec2:instances"
      name      = "SpotMaxPrice"
      value     = var.spot_price
    }
  }

  
  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "SPRING_PROFILES_ACTIVE"
    value = "dev"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MAIN_DB_NAME"
    value = module.main_db.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MAIN_DB_HOST"
    value = module.main_db.host
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MAIN_DB_PORT"
    value = module.main_db.port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MAIN_DB_USER"
    value = module.main_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MAIN_DB_PASSWORD"
    value = module.main_db.password
  }

  dynamic "setting" {
    for_each = var.env
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = setting.key
      value = setting.value
    }
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = var.enable_logging
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = var.delete_logs_on_terminate
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.logs_retention
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
}

locals {
  ports = join(",\n", [
  for port in var.ports :
  <<-EOF
      EXPOSE ${port}
    EOF
  ])
}

data "archive_file" "latest" {
  type        = "zip"
  output_path = "${path.module}/files/latest.zip"
  source {
    content  = <<-EOF
      FROM ${var.image}
      ${local.ports}
    EOF
    filename = "Dockerfile"
  }

  source {
    content  = <<-EOF
files:
  "/opt/aws/amazon-cloudwatch-agent/bin/config.json":
    mode: "000600"
    owner: root
    group: root
    content: |
      {
        "agent": {
          "metrics_collection_interval": 60,
          "run_as_user": "root"
        },
        "metrics": {
          "append_dimensions": {
            "InstanceId": "$${aws:InstanceId}"
          },
          "metrics_collected": {
            "mem": {
              "measurement": [
                "mem_free",
                "mem_used_percent"
              ]
            }
          }
        }
      }
container_commands:
  apply_config_metrics:
    command: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
  apply_default_log_config:
    command: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a append-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/beanstalk.json

EOF

    filename = ".ebextensions/cloudwatch.config"
  }
}

resource "aws_s3_bucket" "eb" {
  bucket = "${var.name}-latest"
}

resource "aws_s3_object" "docker" {
  bucket = aws_s3_bucket.eb.bucket
  key    = "latest.zip"
  source = data.archive_file.latest.output_path
}

resource "aws_elastic_beanstalk_application_version" "latest" {
  name        = "latest"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.eb.bucket
  key         = "latest.zip"

  depends_on = [aws_s3_object.docker]
}