terraform {
  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "template-config/terraform.tfstate"
    region = "eu-west-3"
  }
}

locals {
  ec2_sg                = data.terraform_remote_state.networking.outputs.ec2_sg
  alb_access_sg         = data.terraform_remote_state.networking.outputs.alb_sg
  cluster_sg            = data.terraform_remote_state.networking.outputs.cluster_eks_sg
  private_subnets       = split(",", data.terraform_remote_state.networking.outputs.private_subnets)
  vpc_id                = data.terraform_remote_state.networking.outputs.vpc_id
  aws_alb_iam_role_name = data.terraform_remote_state.eks.outputs.aws_iam_alb_role_name
  aws_alb_iam_role_arn  = data.terraform_remote_state.eks.outputs.aws_iam_alb_role_arn
  argocd_ecr_role_arn   = data.terraform_remote_state.eks.outputs.argocd_ecr_role_arn
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

data "template_file" "install_alb_k8s_manifests_argocd_tmpl" {
  template = file("${var.scripts_template_folder}/install-alb-k8s-manifests-argocd.tmpl")
  vars = {
    cluster_name     = var.cluster_name
    region           = var.region
    vpc_id           = local.vpc_id
    aws_alb_iam_role = local.aws_alb_iam_role_name
    argocd_role_arn  = local.argocd_ecr_role_arn
  }
}

resource "local_file" "install_alb_k8s_manifests_argocd_tmpl" {
  filename = "${var.scripts_rendered_folder}/install-alb-k8s-manifests-argocd.sh"
  content  = data.template_file.install_alb_k8s_manifests_argocd_tmpl.rendered
}

data "template_file" "ingress_tmpl" {
  template = file("${var.k8s_manifests_template_folder}/ingress.tmpl")
  vars = {
    sg_alb = local.alb_access_sg
  }
}

resource "local_file" "ingress" {
  filename = "${var.k8s_manifests_rendered_folder}/ingress.yaml"
  content  = data.template_file.ingress_tmpl.rendered
}

data "template_file" "alb_serviceAccount_tmpl" {
  template = file("${var.service_accounts_template_folder}/alb_serviceAccount.tmpl")
  vars = {
    cluster_name          = var.cluster_name
    region                = var.region
    aws_alb_iam_role_arn  = local.aws_alb_iam_role_arn
    aws_alb_iam_role_name = local.aws_alb_iam_role_name
  }
}

resource "local_file" "alb_serviceAccount_tmpl" {
  filename = "${var.service_accounts_rendered_folder}/alb_serviceAccount.yaml"
  content  = data.template_file.alb_serviceAccount_tmpl.rendered
}

data "template_file" "alb_values_tmpl" {
  template = file("${var.charts_values_template_folder}/alb_values.tmpl")
  vars = {
    cluster_name          = var.cluster_name
    region                = var.region
    vpc_id                = local.vpc_id
    aws_alb_iam_role_name = local.aws_alb_iam_role_name
  }
}

resource "local_file" "alb_values_tmpl" {
  filename = "${var.charts_values_rendered_folder}/alb_values.yaml"
  content  = data.template_file.alb_values_tmpl.rendered
}


data "template_file" "deployment_green_tmpl" {
  template = file("${var.k8s_manifests_template_folder}/deployment_green.tmpl")
  vars = {
    ecr_url = var.ecr_url
  }
}

resource "local_file" "deployment_green_tmpl" {
  filename = "${var.k8s_manifests_rendered_folder}/deployment_green.yaml"
  content  = data.template_file.deployment_green_tmpl.rendered
}

data "template_file" "deployment_blue_tmpl" {
  template = file("${var.k8s_manifests_template_folder}/deployment_blue.tmpl")
  vars = {
    ecr_url = var.ecr_url
  }
}

resource "local_file" "deployment_blue_tmpl" {
  filename = "${var.k8s_manifests_rendered_folder}/deployment_blue.yaml"
  content  = data.template_file.deployment_blue_tmpl.rendered
}
