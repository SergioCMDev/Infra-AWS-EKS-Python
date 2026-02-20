terraform {
  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "security/terraform.tfstate"
    region = "eu-west-3"
  }
}

locals {
  vpc_id           = data.terraform_remote_state.networking.outputs.vpc_id
  aws_alb_iam_role = data.terraform_remote_state.eks.outputs.aws_iam_alb_role_name
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "1-networking/terraform.tfstate"
    region = "eu-west-3"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "2-eks/terraform.tfstate"
    region = "eu-west-3"
  }
}
