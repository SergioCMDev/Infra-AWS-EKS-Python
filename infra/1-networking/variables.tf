variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "mi-cluster"
}

variable "bucket_name" {
  description = "Bucket Name"
  type        = string
  default     = "my-terraform-project-bucket-aws-tokio-2"
}

variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}


variable "availability_zones" {
  description = "Environment"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "private_nets_cidr" {
  description = "Private nets CIDR"
  type        = list(string)
  default     = ["124.0.3.0/24", "124.0.4.0/24"]
}

variable "public_nets_cidr" {
  description = "Public nets CIDR"
  type        = list(string)
  default     = ["124.0.1.0/24", "124.0.2.0/24"]
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "124.0.0.0/16"
}
