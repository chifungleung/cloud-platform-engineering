include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/transit-gateway"
}

dependency "egress_vpc" {
  config_path = "../egress-vpc"

  mock_outputs = {
    vpc_id                    = "vpc-00000000"
    tgw_attachment_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name        = "dev-ou-tgw"
  description = "Transit Gateway for DEV OU hub-and-spoke egress via network-dev NFW"

  vpc_id                    = dependency.egress_vpc.outputs.vpc_id
  tgw_attachment_subnet_ids = dependency.egress_vpc.outputs.tgw_attachment_subnet_ids

  # Replace MGMT_ACCOUNT_ID and the OU path with real values from AWS Organizations.
  ram_principal_arns = [
    "arn:aws:organizations::MGMT_ACCOUNT_ID:ou/o-ORGID/ou-XXXX-XXXXXXXX"
  ]
}
