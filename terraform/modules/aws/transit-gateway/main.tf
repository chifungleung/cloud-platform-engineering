resource "aws_ec2_transit_gateway" "this" {
  description                     = var.description
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = merge({ Name = var.name }, var.tags)
}

# Hub VPC attachment — connects the egress VPC to the TGW via its dedicated TGW attachment subnets.
# The network-firewall module already routes 0.0.0.0/0 in those subnets to the NFW endpoint.
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.tgw_attachment_subnet_ids

  tags = merge({ Name = "${var.name}-hub-attachment" }, var.tags)
}

resource "aws_ram_resource_share" "this" {
  name                      = "${var.name}-share"
  allow_external_principals = false

  tags = merge({ Name = "${var.name}-share" }, var.tags)
}

resource "aws_ram_resource_association" "tgw" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  for_each = toset(var.ram_principal_arns)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this.arn
}
