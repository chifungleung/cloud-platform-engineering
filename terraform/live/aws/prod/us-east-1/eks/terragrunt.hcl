include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/aws/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnet_ids = ["subnet-00000001", "subnet-00000002"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  cluster_name    = "prod-eks"
  cluster_version = "1.30"
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["m5.large"]
      min_size       = 3
      max_size       = 10
      desired_size   = 5
    }
  }
}
