locals {
  region                                    = "eu-west-3"
  vpc_cidr                                  = "124.0.0.0/16"
  availability_zones                        = ["eu-west-3a", "eu-west-3b"]
  public_nets_cidr                          = ["124.0.1.0/24", "124.0.2.0/24"]
  private_nets_cidr                         = ["124.0.3.0/24", "124.0.4.0/24"]
  env                                       = "dev"
  instance_type                             = "t3.medium"
  bucket_name                               = "my-terraform-project-bucket-aws-tokio-2"
  cluster_name                              = "mi-cluster"
  scripts_folder                            = "scripts"
  k8s_python_web_manifests_folder           = "k8s_manifests/apps"
  k8s_python_web_manifests_templates_folder = "k8s_manifests_templates"
  k8s_python_web_service_accounts_folder    = "k8s_service_accounts"

  eks_version          = "1.33"
  charts_values_folder = "charts/values"
}

variable "ecr_url" {
  description = "ECR URL"
  type        = string
}
