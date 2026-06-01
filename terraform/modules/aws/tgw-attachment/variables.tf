variable "name" {
  type        = string
  description = "Name prefix for all resources."
}

variable "transit_gateway_id" {
  type        = string
  description = "ID of the Transit Gateway to attach to."
}

variable "vpc_id" {
  type        = string
  description = "ID of the spoke VPC to attach."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs (private subnets) to use for the TGW VPC attachment."
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private route table IDs to add a default route (0.0.0.0/0) pointing to the TGW."
}

variable "tags" {
  type    = map(string)
  default = {}
}
