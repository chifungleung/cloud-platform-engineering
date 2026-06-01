include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/vpc"
}

inputs = {
  name            = "public-web-app-dev-01-vpc"
  cidr_block      = "10.10.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  enable_nat_gateway         = false
  use_transit_gateway_egress = true
}
