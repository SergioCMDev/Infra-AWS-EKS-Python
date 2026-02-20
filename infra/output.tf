output "alb_sg" {
  value       = aws_security_group.alb_access_sg.id
  description = "alb_sg"
}

output "public_subnets" {
  value       = join(",", aws_subnet.public_net[*].id)
  description = "public_subnets"
}
output "aws_load_balancer_controller_role_arn" {
  value       = aws_iam_role.aws_load_balancer_controller.arn
  description = "ARN del IAM role para el AWS Load Balancer Controller"
}

output "VPC_ID" {
  value       = aws_vpc.vpc.id
  description = "VPC_ID"
}

output "argocd_ecr_role_arn" {
  value       = aws_iam_role.argocd_ecr_pull.arn
  description = "ARN del rol para ArgoCD pull ECR"
}
