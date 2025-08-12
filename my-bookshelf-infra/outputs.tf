output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "node_group_name" {
  value = module.node_group.node_group_name
}

output "node_group_arn" {
  value = module.node_group.node_group_arn
}

output "eso_irsa_role_arn" {
  value = module.eks.eso_irsa_role_arn
}
