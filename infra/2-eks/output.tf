output "aws_iam_alb_role_name" {
  value       = aws_iam_role.aws_load_balancer_controller.name
  description = "aws_iam_alb_role_name"
}

output "aws_iam_alb_role_arn" {
  value       = aws_iam_role.aws_load_balancer_controller.arn
  description = "ARN del IAM role para el AWS Load Balancer Controller"
}

output "argocd_ecr_role_arn" {
  value       = aws_iam_role.argocd_ecr_pull.arn
  description = "ARN del rol para ArgoCD pull ECR"
}

output "eks_oidc_connect_provider_arn" {
  value       = aws_iam_openid_connect_provider.eks.arn
  description = "ARN de OIDC provider de EKS"
}


output "ecr_pods_pull_policy_arn" {
  value       = aws_iam_role.pods_ecr_accces.arn
  description = "ARN del rol de los pods para hacer pull en ECR"
}
