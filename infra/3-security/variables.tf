variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "mi-cluster"
}

variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}



variable "region" {
  description = "Region"
  type        = string
  default     = "eu-west-3"
}
