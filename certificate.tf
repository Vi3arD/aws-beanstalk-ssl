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