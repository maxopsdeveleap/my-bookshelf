include "root" {
  path = find_in_parent_folders()
}

locals {
  environment = "prod"
  
  # Network configuration
  vpc_cidr = "10.20.0.0/16"
  azs = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24"]
  
  # EKS configuration
  cluster_version = "1.28"
  
  # Node group configuration
  instance_type    = "t3a.medium"
  desired_capacity = 3
  max_capacity     = 3
  min_capacity     = 2
}

inputs = {
  environment          = local.environment
  vpc_cidr            = local.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  cluster_version     = local.cluster_version
  instance_type       = local.instance_type
  desired_capacity    = local.desired_capacity
  max_capacity        = local.max_capacity
  min_capacity        = local.min_capacity
  
  environment_tags = {
    Environment = local.environment
    Purpose     = "production-workload"
  }
}
