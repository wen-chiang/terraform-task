locals {
  base_name = lower(replace("${var.naming_prefix}-sg-${var.resource_name}", "_", "-"))
  tags = merge(var.tags, {
    Module = "security_group"
  })
}

resource "aws_security_group" "app" {
  name        = "${local.base_name}-app"
  description = "Application security group"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = "${local.base_name}-app"
    Role = "app"
  })
}

resource "aws_security_group_rule" "app_ingress" {
  for_each = {
    for idx, rule in var.app_ingress_rules : idx => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress" {
  for_each = {
    for idx, rule in var.app_egress_rules : idx => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr_block]
  description       = each.value.description
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group" "db" {
  name        = "${local.base_name}-db"
  description = "Database security group"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = "${local.base_name}-db"
    Role = "db"
  })
}

resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
  description              = "Allow app SG to reach DB port"
}

resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound traffic"
}
