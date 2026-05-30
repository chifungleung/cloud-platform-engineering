include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../modules/aws/ec2"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id            = "vpc-00000000"
    public_subnet_ids = ["subnet-00000001", "subnet-00000002"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name               = "public-web-app-dev-01"
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_id          = dependency.vpc.outputs.public_subnet_ids[0]
  instance_type      = "t3.small"
  ami_id             = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1 — update as needed
  associate_public_ip = true

  ingress_rules = [
    { port = 80,  protocol = "tcp", cidr = "0.0.0.0/0",  description = "HTTP" },
    { port = 443, protocol = "tcp", cidr = "0.0.0.0/0",  description = "HTTPS" },
    { port = 22,  protocol = "tcp", cidr = "10.0.0.0/8", description = "SSH from internal only" },
  ]
}
