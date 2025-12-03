terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-project-bucket-aws-tokio-2"
    key    = "terraform-state"
    region = "eu-west-3"
  }
}
