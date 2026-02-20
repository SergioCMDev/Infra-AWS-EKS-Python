output "ecr_repository_url" {
  value       = aws_ecr_repository.python_web_app.repository_url
  description = "URL del repositorio ECR"
}

output "ecr_repository_iam_role_github_actions_arn" {
  value       = aws_iam_role.ecr_iam_github_actions_role.arn
  description = "ARN del Rol IAM para Github Actions del repositorio ECR"
}
