resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name}-igw" }, var.tags)
}

resource "aws_subnet" "tgw_attachment" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_attachment_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({ Name = "${var.name}-tgw-${var.azs[count.index]}" }, var.tags)
}

resource "aws_subnet" "firewall" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.firewall_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({ Name = "${var.name}-firewall-${var.azs[count.index]}" }, var.tags)
}

resource "aws_subnet" "public" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({ Name = "${var.name}-public-${var.azs[count.index]}" }, var.tags)
}

resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags       = merge({ Name = "${var.name}-nat-eip-${var.azs[count.index]}" }, var.tags)
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags       = merge({ Name = "${var.name}-nat-${var.azs[count.index]}" }, var.tags)
  depends_on = [aws_internet_gateway.this]
}

# Per-AZ route tables — no inline routes; all non-IGW routes owned by the network-firewall module.

resource "aws_route_table" "tgw_attachment" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name}-tgw-rt-${var.azs[count.index]}" }, var.tags)
}

resource "aws_route_table" "firewall" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name}-firewall-rt-${var.azs[count.index]}" }, var.tags)
}

resource "aws_route_table" "public" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name}-public-rt-${var.azs[count.index]}" }, var.tags)
}

# Only the IGW default route is set here; RFC1918 return routes are added by the firewall module.
resource "aws_route" "public_default_igw" {
  count = length(var.azs)

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "tgw_attachment" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.tgw_attachment[count.index].id
  route_table_id = aws_route_table.tgw_attachment[count.index].id
}

resource "aws_route_table_association" "firewall" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}
