remote_state {
  backend = "s3"
  config = {
    bucket         = "max-terraform-s3"
    key            = "my-bookshelf/${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
EOF
}

inputs = {
  project = "max-my-bookshelf"
  global_tags = {
    owner           = "max.strunin"
    Bootcamp        = "BC24"
    expiration_date = "10-10-25"
    project         = "my-bookshelf"
    managed_by      = "terragrunt"
  }
}
