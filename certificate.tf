############################################################
# Create cert for specified domain case
############################################################

provider "acme" {
  #  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data "aws_route53_zone" "base_domain" {
  name = var.hosted_zone
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "admin@${var.hosted_zone}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = data.aws_route53_zone.base_domain.name
  subject_alternative_names = var.san

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.base_domain.zone_id
    }
  }

  depends_on = [acme_registration.registration]
}

resource "aws_acm_certificate" "certificate" {
  certificate_body  = acme_certificate.certificate.certificate_pem
  private_key       = acme_certificate.certificate.private_key_pem
  certificate_chain = acme_certificate.certificate.issuer_pem
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