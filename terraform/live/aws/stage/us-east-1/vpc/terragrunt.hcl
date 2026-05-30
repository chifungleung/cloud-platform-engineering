include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/aws/vpc"
}

inputs = {
  name             = "stage-vpc"
  cidr_block       = "10.1.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets   = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  enable_nat_gateway = true
}
