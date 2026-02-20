terraform {
  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "2-eks/terraform.tfstate"
    region = "eu-west-3"
  }
}

locals {
  ec2_sg          = data.terraform_remote_state.networking.outputs.ec2_sg
  alb_access_sg   = data.terraform_remote_state.networking.outputs.alb_sg
  cluster_sg      = data.terraform_remote_state.networking.outputs.cluster_eks_sg
  private_subnets = split(",", data.terraform_remote_state.networking.outputs.private_subnets)
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "1-networking/terraform.tfstate"
    region = "eu-west-3"
  }
}
