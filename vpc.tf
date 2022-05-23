data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs_count  = max(2, min(
    var.azs_count != null ? var.azs_count : length(data.aws_availability_zones.available.names),
    length(data.aws_availability_zones.available.names)
  ))
  azs        = slice(data.aws_availability_zones.available.names, 0, local.azs_count)

  subnet_count = var.use_private_subnets ? local.azs_count * 3 : local.azs_count
  cidr_new_bits = ceil(log(local.subnet_count, 2))
  subnets = [for i in range(local.subnet_count): cidrsubnet(var.vpc_cidr_block, local.cidr_new_bits, i)]
  public_subnets = slice(local.subnets, 0, local.azs_count)
  private_subnets = var.use_private_subnets ? slice(local.subnets, local.azs_count, 2 * local.azs_count) : []
  db_subnets = var.use_private_subnets ? slice(local.subnets, 2 * local.azs_count, 3 * local.azs_count) : []

  create_igw = length(local.public_subnets) > 0
}

############################################################
# VPC
############################################################

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

############################################################
# Internet Gateway
############################################################

resource "aws_internet_gateway" "igw" {
  count  = local.create_igw ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

############################################################
# NAT Gateway
############################################################

resource "aws_eip" "nat" {
  count = var.use_private_subnets ? 1 : 0

  vpc = true

  tags = {
    Name = "${var.name}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.use_private_subnets ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(aws_subnet.public[*].id, 0)

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.name}-nat"
  }
}

############################################################
# Public subnets
############################################################

resource "aws_subnet" "public" {
  count             = length(local.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.public_subnets, count.index)
  availability_zone = element(local.azs, count.index)

  tags = {
    Name = "${var.name}-public-${count.index}"
  }
}

############################################################
# Private subnets
############################################################

resource "aws_subnet" "private" {
  count             = var.use_private_subnets ? length(local.private_subnets) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.private_subnets, count.index)
  availability_zone = element(local.azs, count.index)

  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}


############################################################
# Database subnets
############################################################

resource "aws_subnet" "db" {
  count             = var.use_private_subnets ? length(local.db_subnets) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.db_subnets, count.index)
  availability_zone = element(local.azs, count.index)

  tags = {
    Name = "${var.name}-db-${count.index}"
  }
}

############################################################
# Public routes
############################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "igw" {
  count                  = local.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_internet_gateway.igw[*].id, 0)

  timeouts {
    create = "5m"
  }
}

############################################################
# Private routes
############################################################

resource "aws_route_table" "private" {
  count = var.use_private_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private"
  }
}

resource "aws_route" "private_nat" {
  count = var.use_private_subnets ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id

  timeouts {
    create = "5m"
  }
}

############################################################
# DB routes
############################################################

resource "aws_route_table" "db" {
  count = var.use_private_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-db"
  }
}

resource "aws_route" "db_nat" {
  count = var.use_private_subnets ? 1 : 0

  route_table_id         = aws_route_table.db[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id

  timeouts {
    create = "5m"
  }
}

############################################################
# Route table association
############################################################

resource "aws_route_table_association" "public" {
  count = length(local.public_subnets)

  route_table_id = aws_route_table.public.id
  subnet_id      = element(aws_subnet.public[*].id, count.index)
}

resource "aws_route_table_association" "private" {
  count = var.use_private_subnets ? length(local.private_subnets) : 0

  route_table_id = aws_route_table.private[0].id
  subnet_id      = element(aws_subnet.private[*].id, count.index)
}

resource "aws_route_table_association" "db" {
  count = var.use_private_subnets ? length(local.db_subnets) : 0

  route_table_id = aws_route_table.db[0].id
  subnet_id      = element(aws_subnet.db[*].id, count.index)
}

resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.name}-db-"
  subnet_ids  = var.use_private_subnets ? aws_subnet.db[*].id : aws_subnet.public[*].id

  tags = {
    "Name" = var.name
  }
}