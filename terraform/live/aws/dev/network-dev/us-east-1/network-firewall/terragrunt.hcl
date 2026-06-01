include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/network-firewall"
}

dependency "egress_vpc" {
  config_path = "../egress-vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    firewall_subnet_id_by_az = {
      "us-east-1a" = "subnet-aaaaaaaa"
      "us-east-1b" = "subnet-bbbbbbbb"
    }
    tgw_attachment_route_table_id_by_az = {
      "us-east-1a" = "rtb-aaaaaaaa"
      "us-east-1b" = "rtb-bbbbbbbb"
    }
    firewall_route_table_id_by_az = {
      "us-east-1a" = "rtb-cccccccc"
      "us-east-1b" = "rtb-dddddddd"
    }
    public_route_table_id_by_az = {
      "us-east-1a" = "rtb-eeeeeeee"
      "us-east-1b" = "rtb-ffffffff"
    }
    nat_gateway_id_by_az = {
      "us-east-1a" = "nat-aaaaaaaa"
      "us-east-1b" = "nat-bbbbbbbb"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name    = "network-dev-nfw"
  vpc_id  = dependency.egress_vpc.outputs.vpc_id

  firewall_subnet_id_by_az            = dependency.egress_vpc.outputs.firewall_subnet_id_by_az
  tgw_attachment_route_table_id_by_az = dependency.egress_vpc.outputs.tgw_attachment_route_table_id_by_az
  firewall_route_table_id_by_az       = dependency.egress_vpc.outputs.firewall_route_table_id_by_az
  public_route_table_id_by_az         = dependency.egress_vpc.outputs.public_route_table_id_by_az
  nat_gateway_id_by_az                = dependency.egress_vpc.outputs.nat_gateway_id_by_az

  home_networks           = ["10.0.0.0/8"]
  stateful_default_action = "DROP_STRICT"
}
