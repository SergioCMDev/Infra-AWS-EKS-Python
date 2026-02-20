variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "mi-cluster"
}


variable "region" {
  description = "Region"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "Instance types for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "bucket_name" {
  description = "Bucket Name"
  type        = string
  default     = "my-terraform-project-bucket-aws-tokio-2"
}

variable "ecr_url" {
  description = "ECR URL"
  type        = string
}
