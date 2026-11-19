output "app_sg_id" {
  description = "Application security group ID."
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Database security group ID."
  value       = aws_security_group.db.id
}

output "alb_sg_id" {
  description = "Application load balancer security group ID."
  value       = aws_security_group.alb.id
}
