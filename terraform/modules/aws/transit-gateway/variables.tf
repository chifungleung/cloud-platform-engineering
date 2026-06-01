variable "name" {
  type        = string
  description = "Name prefix for all resources."
}

variable "description" {
  type        = string
  default     = ""
  description = "Description for the Transit Gateway."
}

variable "vpc_id" {
  type        = string
  description = "ID of the hub (egress) VPC to attach to the Transit Gateway."
}

variable "tgw_attachment_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs (one per AZ) in the egress VPC for the TGW attachment."
}

variable "ram_principal_arns" {
  type        = list(string)
  default     = []
  description = "List of AWS Organization OU or account ARNs to share the Transit Gateway with via RAM."
}

variable "tags" {
  type    = map(string)
  default = {}
}
