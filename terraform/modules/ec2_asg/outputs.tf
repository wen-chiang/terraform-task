output "module_name" {
  value = local.module_name
}

output "asg_name" {
  value = length(aws_autoscaling_group.this) > 0 ? aws_autoscaling_group.this[0].name : null
}
