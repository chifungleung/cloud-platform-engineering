variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "associate_public_ip" {
  description = "Associate a public IP address"
  type        = bool
  default     = false
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr        = string
    description = string
  }))
  default = []
}
