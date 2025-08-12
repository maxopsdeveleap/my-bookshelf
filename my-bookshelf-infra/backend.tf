terraform {
  backend "s3" {
    bucket        = "max-terraform-s3"
    key           = "my-bookshelf/terraform.tfstate"
    region        = "ap-south-1"
    use_lockfile  = true
  }
}
