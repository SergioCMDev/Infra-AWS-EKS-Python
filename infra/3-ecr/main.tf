terraform {
  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "ecr/terraform.tfstate"
    region = "eu-west-3"
  }
}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "2-eks/terraform.tfstate"
    region = "eu-west-3"
  }
}


locals {
  argocd_ecr_role_arn      = data.terraform_remote_state.eks.outputs.argocd_ecr_role_arn
  ecr_pods_pull_policy_arn = data.terraform_remote_state.eks.outputs.ecr_pods_pull_policy_arn
}
