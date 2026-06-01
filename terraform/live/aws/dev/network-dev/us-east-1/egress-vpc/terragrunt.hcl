include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/egress-vpc"
}

inputs = {
  name       = "network-dev-egress-vpc"
  cidr_block = "10.21.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  # /28 is sufficient for TGW attachment and firewall endpoint subnets (single ENI per subnet)
  tgw_attachment_subnets = ["10.21.0.0/28", "10.21.0.16/28"]
  firewall_subnets       = ["10.21.1.0/28", "10.21.1.16/28"]
  public_subnets         = ["10.21.2.0/24", "10.21.3.0/24"]
}
