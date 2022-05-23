resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key" {
  key_name_prefix = "${var.name}-"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key_ssh" {
  content  = tls_private_key.this.private_key_pem
  filename = "${path.module}/ssh/aws.pem"
  file_permission = "0400"
}