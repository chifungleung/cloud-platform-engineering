variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of availability zones — must match the length of all subnet lists"
  type        = list(string)
}

variable "tgw_attachment_subnets" {
  description = "CIDR blocks for Transit Gateway attachment subnets, one per AZ"
  type        = list(string)
}

variable "firewall_subnets" {
  description = "CIDR blocks for Network Firewall endpoint subnets, one per AZ"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (NAT Gateway + IGW), one per AZ"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
