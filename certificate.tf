############################################################
# Self-signed cert case
############################################################

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "certificate" {
  private_key_pem = tls_private_key.rsa.private_key_pem

  subject {
    common_name  = "${local.beanstalk_prefix}.${var.region}.elasticbeanstalk.com"
    organization = var.name
  }

  validity_period_hours = 720

  allowed_uses = [
    "any_extended",
    "cert_signing",
    "client_auth",
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "certificate" {
  certificate_body = tls_self_signed_cert.certificate.cert_pem
  private_key      = tls_private_key.rsa.private_key_pem
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
      values = ["${local.beanstalk_prefix}.${var.region}.elasticbeanstalk.com"]
    }
  }
}