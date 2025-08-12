variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to launch nodes in (private recommended)"
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the node group"
  type        = string
}

variable "desired_capacity" {
  description = "Desired node count"
  type        = number
}

variable "max_capacity" {
  description = "Max node count"
  type        = number
}

variable "min_capacity" {
  description = "Min node count"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
}

variable "cluster_role_arn" {
  description = "EKS cluster role ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
