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

output "ecr_repository_url" {
  value       = aws_ecr_repository.python_web_app.repository_url
  description = "URL del repositorio ECR"
}
