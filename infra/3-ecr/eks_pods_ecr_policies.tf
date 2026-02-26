resource "aws_ecr_repository_policy" "app_pull_policy" {
  repository = aws_ecr_repository.python_web_app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            local.argocd_ecr_role_arn,
            local.ecr_pods_pull_policy_arn
          ]
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
      }
    ]
  })
}
