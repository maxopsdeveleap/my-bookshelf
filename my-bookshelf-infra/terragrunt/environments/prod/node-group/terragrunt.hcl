include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../modules/node-group"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_name = "mock-cluster"
    cluster_arn  = "arn:aws:eks:ap-south-1:123456789012:cluster/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  cluster_name     = dependency.eks.outputs.cluster_name
  subnet_ids       = dependency.vpc.outputs.private_subnet_ids
  node_group_name  = "max-node-group"
  cluster_role_arn = dependency.eks.outputs.cluster_arn
  instance_type    = dependency.env.outputs.instance_type
  desired_capacity = dependency.env.outputs.desired_capacity
  max_capacity     = dependency.env.outputs.max_capacity
  min_capacity     = dependency.env.outputs.min_capacity
}
