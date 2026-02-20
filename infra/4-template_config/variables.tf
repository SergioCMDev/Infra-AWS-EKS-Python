variable "k8s_manifests_template_folder" {
  description = "k8s manifests template folder"
  type        = string
  default     = "templates/k8s"
}

variable "k8s_manifests_rendered_folder" {
  description = "k8s manifests rendered folder"
  type        = string
  default     = "rendered/k8s"
}

variable "service_accounts_template_folder" {
  description = "service accounts template folder"
  type        = string
  default     = "templates/charts_service_accounts"
}

variable "service_accounts_rendered_folder" {
  description = "service accounts rendered folder"
  type        = string
  default     = "rendered/charts_service_accounts"
}

variable "scripts_template_folder" {
  description = "scripts template folder"
  type        = string
  default     = "templates/scripts"
}

variable "scripts_rendered_folder" {
  description = "scripts rendered folder"
  type        = string
  default     = "rendered/scripts"
}

variable "charts_values_template_folder" {
  description = "scripts template folder"
  type        = string
  default     = "templates/charts_values"
}

variable "charts_values_rendered_folder" {
  description = "charts values rendered folder"
  type        = string
  default     = "rendered/charts_values"
}

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

variable "ecr_url" {
  description = "ECR URL"
  type        = string
}
