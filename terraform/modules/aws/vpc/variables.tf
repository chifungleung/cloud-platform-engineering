variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for private subnet egress"
  type        = bool
  default     = true
}

variable "use_transit_gateway_egress" {
  description = "When true, skip the NAT default route in private route tables (a TGW attachment will provide egress instead)."
  type        = bool
  default     = false
}
