locals {
  use_nat_gateway = var.enable_nat_gateway == null ? var.network_defaults.enable_nat_gateway : var.enable_nat_gateway

  name_prefix = lower(replace("${var.naming_prefix}-vpc-${var.resource_name}", "_", "-"))

  merged_tags = merge(var.tags, {
    Module = "vpc"
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.merged_tags, {
    Name = local.name_prefix
  })
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = true

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  count  = length(aws_subnet.public) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  count = length(aws_route_table.public) > 0 && length(aws_internet_gateway.this) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count = local.use_nat_gateway && length(aws_subnet.public) > 0 && length(aws_subnet.private) > 0 ? 1 : 0

  domain = "vpc"

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.use_nat_gateway && length(aws_subnet.public) > 0 && length(aws_subnet.private) > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(local.merged_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  count = length(aws_route_table.private) > 0 && length(aws_nat_gateway.this) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
