############################################################
# Self-signed cert case
############################################################
resource "random_string" "random" {
  length  = 16
  special = false
}

locals {
  beanstalk_prefix = "${var.name}-${random_string.random}"
}