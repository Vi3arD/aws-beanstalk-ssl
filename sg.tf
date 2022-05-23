resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.main.id
  name_prefix = "${var.name}-instance-"
}