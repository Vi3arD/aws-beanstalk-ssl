############################################################
# Create cert for specified domain case in AWS
############################################################

data "aws_route53_zone" "base_domain" {
  name = var.hosted_zone
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.hosted_zone
  subject_alternative_names = var.san
  validation_method         = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validated : record.fqdn]
}

resource "aws_route53_record" "validated" {
  for_each = {
  for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.base_domain.zone_id
}

resource "aws_route53_record" "lb" {
  for_each = var.san
  zone_id  = data.aws_route53_zone.base_domain.zone_id
  name     = each.value
  type     = "CNAME"
  ttl      = "300"
  records  = [aws_elastic_beanstalk_environment.env.endpoint_url]
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
      values = [join(",", var.san)]
    }
  }
}