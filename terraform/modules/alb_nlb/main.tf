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
    healthy_threshold   = try(each.value.health_check.healthy_threshold, 2)
    unhealthy_threshold = try(each.value.health_check.unhealthy_threshold, 2)
    timeout             = try(each.value.health_check.timeout, 5)
    interval            = try(each.value.health_check.interval, 30)
    matcher             = try(each.value.health_check.matcher, "200")
  }

  target_type = try(each.value.target_type, "instance")

  tags = merge(var.tags, try(each.value.tags, {}), { Module = local.module_name })
}

resource "aws_lb_listener" "https" {
  count = length(aws_lb.this) > 0 && try(local.settings.certificate_arn, "") != "" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = try(local.settings.listener_port, 443)
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.settings.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = values(aws_lb_target_group.this)[0].arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count = length(aws_lb.this) > 0 && try(local.settings.certificate_arn, "") != "" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
