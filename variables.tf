locals {
  region                      = "eu-west-3"
  vpc_cidr                    = "124.0.0.0/16"
  availability_zones          = ["eu-west-3a", "eu-west-3b"]
  public_nets_cidr            = ["124.0.1.0/24", "124.0.2.0/24"]
  private_nets_cidr           = ["124.0.3.0/24", "124.0.4.0/24"]
  env                         = "dev"
  instance_type               = "t3.medium"
  bucket_name                 = "my-terraform-project-bucket-aws-tokio-2"
  cluster_name                = "mi-cluster"
  kubernetes_version          = "v1.33"
  alb_controller_version      = "v2.7.2"
  scripts_folder              = "scripts"
  k8s_manifests_folder        = "k8s_manifests"
  k8s_config_files_folder     = "k8s_config_files"
  github_runner_instance_type = "t3.medium"
  repo_name                   = "PythonWebForIAC"
  repo_user                   = "SergioCMDev"
  token                       = "AAT2HYZ55ONO5NZICN6A73TJAKHUA"
  eks_version                 = "1.33"
  ami_image                   = "ami-0a8e052d7bc893af0"
  runner_name                 = "aws-runner-${local.env}"
}

variable "runner_version" {
  description = "GitHub Actions Runner version"
  type        = string
  default     = "2.329.0"
}

variable "runner_labels" {
  type    = string
  default = "aws,amazon-linux,production"
}
