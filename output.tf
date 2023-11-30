output "db_endpoint" {
  value      = aws_db_instance.my_db_instance.endpoint
  depends_on = [aws_db_instance.my_db_instance]
}

output "db_port" {
  value      = aws_db_instance.my_db_instance.port
  depends_on = [aws_db_instance.my_db_instance]
}
