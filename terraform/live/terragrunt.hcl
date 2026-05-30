# Root Terragrunt config — inherited by all stacks via find_in_parent_folders()

locals {
  # Read account-level vars by walking up to the nearest account.hcl
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  account_id   = local.account_vars.locals.account_id
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region
}

# Remote state: unique S3 key per stack, DynamoDB lock per account
remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-state-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "tf-locks-${local.account_id}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Inject AWS provider into every stack automatically
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  # Role assumed by GitHub Actions OIDC — set via TF_VAR or environment
  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/github-actions-terraform"
  }

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "${local.account_name}"
      Repository  = "cloud-platform-engineering"
    }
  }
}
EOF
}
