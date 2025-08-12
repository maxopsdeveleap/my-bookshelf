variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
  default     = "max-my-bookshelf"
}

variable "global_tags" {
  description = "Global tags for all resources"
  type = map(string)
  default = {
    owner          = "max.strunin"
    Bootcamp       = "BC24"
    expiration_date = "10-10-25"
    project        = "my-bookshelf"
  }
}

# VPC Module Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

# EKS & Node Group Variables
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3a.medium"
}

variable "node_desired_capacity" {
  description = "Desired node count"
  type        = number
  default     = 3
}

variable "node_max_capacity" {
  description = "Max node count"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Min node count"
  type        = number
  default     = 2
}
