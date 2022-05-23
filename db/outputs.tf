output "id" {
  value = aws_db_instance.db.id
}

output "host" {
  value = aws_db_instance.db.address
}

output "name" {
  value = aws_db_instance.db.name
}

output "port" {
  value = aws_db_instance.db.port
}

output "username" {
  value = aws_db_instance.db.username
}

output "password" {
  value = aws_db_instance.db.password
  sensitive = true
}

output "sg_id" {
  value = aws_security_group.db_sg.id
}

output "sg_name" {
  value = aws_security_group.db_sg.name
}

output "resource_id" {
  value = aws_db_instance.db.resource_id
}
