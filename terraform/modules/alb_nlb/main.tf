locals {
  module_name    = "alb_nlb"
  settings       = try(var.module_settings, {})
  target_groups  = merge(try(local.settings.target_groups, {}), {})
}

resource "aws_lb" "this" {
  count = length(try(local.settings.subnet_ids, [])) > 0 ? 1 : 0

  name               = lower(replace(try(local.settings.name, "${var.naming_prefix}-lb"), "_", "-"))
  internal           = try(local.settings.internal, false)
  load_balancer_type = try(local.settings.load_balancer_type, "application")
  security_groups    = try(local.settings.security_group_ids, null)
  subnets            = local.settings.subnet_ids

  tags = merge(var.tags, try(local.settings.tags, {}), { Module = local.module_name })
}

resource "aws_lb_target_group" "this" {
  for_each = {
    for k, v in local.target_groups : k => v
    if try(local.settings.vpc_id, null) != null
  }

  name     = substr(lower(replace(try(each.value.name, "${var.naming_prefix}-tg-${each.key}"), "_", "-")), 0, 32)
  port     = try(each.value.port, 80)
  protocol = try(each.value.protocol, "HTTP")
  vpc_id   = local.settings.vpc_id

  health_check {
    enabled = try(each.value.health_check_enabled, true)
    path    = try(each.value.health_check_path, "/")
  }

  tags = merge(var.tags, try(each.value.tags, {}), { Module = local.module_name })
}
