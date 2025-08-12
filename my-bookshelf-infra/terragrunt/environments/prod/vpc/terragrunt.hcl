include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  # Inherited from environment
  vpc_cidr             = dependency.env.outputs.vpc_cidr
  azs                  = dependency.env.outputs.azs
  public_subnet_cidrs  = dependency.env.outputs.public_subnet_cidrs
  private_subnet_cidrs = dependency.env.outputs.private_subnet_cidrs
}
