resource "aws_iam_role" "ecr_iam_github_actions_role" {
  name = "ecr_iam_github_actions_role"

  # Trust policy: confía en la ServiceAccount específica
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.repo_name}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecr_push_github_actions_pull_policy" {
  name = "ecr_push_github_actions_pull_policy"
  role = aws_iam_role.ecr_iam_github_actions_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.python_web_app.arn
      },
      { #COMPROBAR
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter"
        ],
        "Resource" : "arn:aws:ssm:${var.region}:${aws_caller_identity.current}:parameter/${var.ssm_paramter}*"
      }
    ]
  })
}
