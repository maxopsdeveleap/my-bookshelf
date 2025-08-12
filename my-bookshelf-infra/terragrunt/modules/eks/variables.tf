variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy EKS into"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS (for load balancers)"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to EKS resources"
  type        = map(string)
}
