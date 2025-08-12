locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  vpc_cidr = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24"]
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = local.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = local.public_subnet_cidrs
  private_subnet_cidrs= local.private_subnet_cidrs
  tags                = var.global_tags
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "${var.project}-eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids   
  public_subnet_ids  = module.vpc.public_subnet_ids
  tags               = var.global_tags
}

module "node_group" {
  source           = "./modules/node_group"
  cluster_name     = module.eks.cluster_name
  subnet_ids       = module.vpc.private_subnet_ids      
  node_group_name  = "max-node-group"
  desired_capacity = 3
  max_capacity     = 3
  min_capacity     = 2
  instance_type    = "t3a.medium"
  cluster_role_arn = module.eks.cluster_arn
  tags = merge(
    var.global_tags,
    { Name = "max-node-group" }
  )
}
