variable "name" {
  description = "Name prefix for all firewall resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the egress VPC"
  type        = string
}

variable "firewall_subnet_id_by_az" {
  description = "Map of availability zone to subnet ID for Network Firewall endpoints"
  type        = map(string)
}

variable "tgw_attachment_route_table_id_by_az" {
  description = "Map of availability zone to route table ID for TGW attachment subnets"
  type        = map(string)
}

variable "firewall_route_table_id_by_az" {
  description = "Map of availability zone to route table ID for firewall subnets"
  type        = map(string)
}

variable "public_route_table_id_by_az" {
  description = "Map of availability zone to route table ID for public subnets"
  type        = map(string)
}

variable "nat_gateway_id_by_az" {
  description = "Map of availability zone to NAT Gateway ID"
  type        = map(string)
}

variable "home_networks" {
  description = "RFC1918 source CIDRs — used as the rule source in stateful PASS rules and as return route destinations"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "stateful_default_action" {
  description = "Default action for unmatched stateful traffic: DROP_STRICT or DROP_ESTABLISHED"
  type        = string
  default     = "DROP_STRICT"
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
