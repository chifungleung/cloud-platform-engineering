output "vpc_id" {
  value = aws_vpc.this.id
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}

output "tgw_attachment_subnet_ids" {
  value = aws_subnet.tgw_attachment[*].id
}

output "firewall_subnet_ids" {
  value = aws_subnet.firewall[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "tgw_attachment_subnet_id_by_az" {
  value = { for i, az in var.azs : az => aws_subnet.tgw_attachment[i].id }
}

output "firewall_subnet_id_by_az" {
  value = { for i, az in var.azs : az => aws_subnet.firewall[i].id }
}

output "public_subnet_id_by_az" {
  value = { for i, az in var.azs : az => aws_subnet.public[i].id }
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}

output "nat_gateway_id_by_az" {
  value = { for i, az in var.azs : az => aws_nat_gateway.this[i].id }
}

output "tgw_attachment_route_table_id_by_az" {
  value = { for i, az in var.azs : az => aws_route_table.tgw_attachment[i].id }
}

output "firewall_route_table_id_by_az" {
  value = { for i, az in var.azs : az => aws_route_table.firewall[i].id }
}

output "public_route_table_id_by_az" {
  value = { for i, az in var.azs : az => aws_route_table.public[i].id }
}
