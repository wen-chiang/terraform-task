output "module_name" { value = local.module_name }
output "lb_dns_name" { value = length(aws_lb.this) > 0 ? aws_lb.this[0].dns_name : null }
output "target_group_arns" {
  value = {
    for k, v in aws_lb_target_group.this : k => v.arn
  }
}

output "lb_arn" {
  value = length(aws_lb.this) > 0 ? aws_lb.this[0].arn : null
}

output "lb_zone_id" {
  value = length(aws_lb.this) > 0 ? aws_lb.this[0].zone_id : null
}
