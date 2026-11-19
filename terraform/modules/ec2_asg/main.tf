locals {
  module_name = "ec2_asg"
  settings    = try(var.module_settings, {})
}

resource "aws_launch_template" "this" {
  count = try(local.settings.image_id, null) != null ? 1 : 0

  name_prefix   = "${var.naming_prefix}-lt-"
  image_id      = local.settings.image_id
  instance_type = try(local.settings.instance_type, "t3.micro")

  vpc_security_group_ids = try(local.settings.security_group_ids, null)
  user_data              = try(local.settings.user_data, null) != null ? base64encode(local.settings.user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name   = "${var.naming_prefix}-ec2-asg"
      Module = local.module_name
    })
  }
}

resource "aws_autoscaling_group" "this" {
  count = length(aws_launch_template.this) > 0 && length(try(local.settings.subnet_ids, [])) > 0 ? 1 : 0

  name                = try(local.settings.name, "${var.naming_prefix}-asg")
  min_size            = try(local.settings.min_size, 1)
  max_size            = try(local.settings.max_size, 3)
  desired_capacity    = try(local.settings.desired_capacity, 1)
  vpc_zone_identifier = local.settings.subnet_ids

  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  target_group_arns = try(local.settings.target_group_arn, "") != "" ? [local.settings.target_group_arn] : null

  tag {
    key                 = "Name"
    value               = try(local.settings.name, "${var.naming_prefix}-asg")
    propagate_at_launch = true
  }
}
