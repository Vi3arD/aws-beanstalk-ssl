############################################################
# Self-signed cert case
############################################################
resource "random_integer" "random" {
  min = 1
  max = 500000
}

locals {
  beanstalk_prefix = "${var.name}-${random_integer.random}"
}