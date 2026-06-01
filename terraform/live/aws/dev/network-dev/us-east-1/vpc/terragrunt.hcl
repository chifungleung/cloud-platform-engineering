include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/vpc"
}

inputs = {
  name            = "network-dev-vpc"
  cidr_block      = "10.20.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  enable_nat_gateway = true
}
