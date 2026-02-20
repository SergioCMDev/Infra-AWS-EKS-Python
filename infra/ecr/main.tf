terraform {
  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "ecr/terraform.tfstate"
    region = "eu-west-3"
  }
}
data "aws_caller_identity" "current" {}
