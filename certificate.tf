############################################################
# Get cert from AWS CM case
############################################################

data "aws_acm_certificate" "certificate" {
  domain = var.certificate_san
}

data "aws_route53_zone" "base_domain" {
  name = var.hosted_zone
}

resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.base_domain.zone_id
  name    = var.certificate_san
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elastic_beanstalk_environment.env.endpoint_url]
}

data "aws_lb_listener" "listener80" {
  load_balancer_arn = aws_elastic_beanstalk_environment.env.load_balancers[0]
  port              = 80
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = data.aws_lb_listener.listener80.arn

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.certificate_san]
    }
  }
}