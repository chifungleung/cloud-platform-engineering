include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/tgw-attachment"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                 = "vpc-00000000"
    private_subnet_ids     = ["subnet-00000001", "subnet-00000002"]
    private_route_table_id = "rtb-00000001"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Cross-account dependency: reads the TGW ID from network-dev's remote state.
# The github-actions-terraform role in this account needs s3:GetObject on
# tf-state-<network-dev-account-id> to resolve this during CI.
dependency "tgw" {
  config_path = "../../../../network-dev/us-east-1/transit-gateway"

  mock_outputs = {
    transit_gateway_id = "tgw-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name               = "public-web-app-dev-01-tgw-attachment"
  transit_gateway_id = dependency.tgw.outputs.transit_gateway_id
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_ids         = dependency.vpc.outputs.private_subnet_ids
  private_route_table_ids = [dependency.vpc.outputs.private_route_table_id]
}
