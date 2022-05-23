locals {
  lb_id       = data.aws_lb.alb.arn_suffix
  instance_id = aws_elastic_beanstalk_environment.env.instances[0]
}

data "aws_lb" "alb" {
  arn = aws_elastic_beanstalk_environment.env.load_balancers[0]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name}-dashboard"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 24,
            "y": 12,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/elasticbeanstalk/${aws_elastic_beanstalk_environment.env.name}/var/log/eb-docker/containers/eb-current-app/stdouterr.log' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
                "region": "${var.region}",
                "stacked": false,
                "title": "Application | Logs",
                "view": "table"
            }
        },
        {
            "height": 6,
            "width": 9,
            "y": 0,
            "x": 9,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "NetworkIn", "InstanceId", "${local.instance_id}" ],
                    [ ".", "NetworkOut", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "Application | NetworkIn, NetworkOut"
            }
        },
        {
            "height": 6,
            "width": 7,
            "y": 18,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${local.lb_id}" ]
                ],
                "region": "${var.region}",
                "title": "LB | RequestCount"
            }
        },
        {
            "height": 6,
            "width": 7,
            "y": 18,
            "x": 7,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${local.lb_id}" ],
                    [ ".", "HTTPCode_ELB_502_Count", ".", "." ],
                    [ ".", "HTTPCode_Target_2XX_Count", ".", "." ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", "." ]
                ],
                "region": "${var.region}",
                "stacked": false,
                "title": "LB | HTTPCode_ELB_4XX_Count, HTTPCode_ELB_502_Count, HTTPCode_ELB_5XX_Count, HTTPCode_Target_2XX_Count"
            }
        },
        {
            "height": 6,
            "width": 7,
            "y": 18,
            "x": 14,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "NewConnectionCount", "LoadBalancer", "${local.lb_id}" ],
                    [ ".", "ActiveConnectionCount", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "LB | ActiveConnectionCount, NewConnectionCount"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 24,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | FreeableMemory"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 24,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | FreeStorageSpace"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 24,
            "x": 12,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${module.main_db.id}" ],
                    [ ".", "WriteIOPS", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "DB | ReadIOPS, WriteIOPS"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 24,
            "x": 18,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | CPUUtilization"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 30,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "WriteLatency", "DBInstanceIdentifier", "${module.main_db.id}", { "color": "#ff7f0e" } ],
                    [ ".", "ReadLatency", ".", ".", { "color": "#1f77b4" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "period": 300,
                "stat": "Average",
                "title": "DB | ReadLatency, WriteLatency"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 30,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "ReadThroughput", "DBInstanceIdentifier", "${module.main_db.id}" ],
                    [ ".", "WriteThroughput", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "DB | ReadThroughput, WriteThroughput"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 30,
            "x": 12,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | DatabaseConnections"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 30,
            "x": 18,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | DiskQueueDepth"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 36,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "SwapUsage", "DBInstanceIdentifier", "${module.main_db.id}" ]
                ],
                "region": "${var.region}",
                "title": "DB | SwapUsage"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 36,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "${module.main_db.id}" ],
                    [ ".", "NetworkReceiveThroughput", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "DB | NetworkReceiveThroughput, NetworkTransmitThroughput"
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "StatusCheckFailed_System", "InstanceId", "${local.instance_id}" ],
                    [ ".", "StatusCheckFailed_Instance", ".", "." ],
                    [ ".", "StatusCheckFailed", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "Application | StatusCheckFailed, StatusCheckFailed_Instance, StatusCheckFailed_System"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 9,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "DiskReadOps", "InstanceId", "${local.instance_id}" ],
                    [ ".", "DiskWriteOps", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "Application | DiskReadOps, DiskWriteOps"
            }
        },
        {
            "type": "metric",
            "x": 9,
            "y": 6,
            "width": 9,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "CPUCreditUsage", "InstanceId", "${local.instance_id}" ],
                    [ ".", "CPUCreditBalance", ".", "." ]
                ],
                "region": "${var.region}",
                "title": "Application | CPUCreditBalance, CPUCreditUsage"
            }
        },
        {
          "type": "metric",
          "height": 6,
          "width": 9,
          "y": 0,
          "x": 0,
          "properties": {
              "metrics": [
                  [ "CWAgent", "mem_total", "InstanceId", "${local.instance_id}" ],
                  [ ".", "mem_free", ".", "." ],
                  [ ".", "mem_used", ".", "." ]
              ],
              "view": "timeSeries",
              "stacked": false,
              "region": "${var.region}",
              "stat": "Average",
              "period": 60
          }
        },
                {
            "type": "log",
            "x": 0,
            "y": 42,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/rds/instance/${module.main_db.id}/postgresql' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
                "region": "${var.region}",
                "stacked": false,
                "view": "table",
                "title": "DB | Logs"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 48,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE 'RDSOSMetrics' | fields @timestamp, @message\n| filter @logStream in [\"${module.main_db.resource_id}\"]\n| sort @timestamp desc\n| limit 20",
                "region": "${var.region}",
                "stacked": false,
                "title": "DB | Enhanced Logs",
                "view": "table"
            }
        }
    ]
}
EOF
}
