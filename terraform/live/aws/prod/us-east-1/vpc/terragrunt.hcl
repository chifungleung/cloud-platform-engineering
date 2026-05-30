include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/aws/vpc"
}

inputs = {
  name             = "prod-vpc"
  cidr_block       = "10.2.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets   = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
  enable_nat_gateway = true
}
