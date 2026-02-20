resource "aws_iam_role" "ec2_workers_role" {
  name = "ec2_workers_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "ec2-workers-profile"
  role = aws_iam_role.ec2_workers_role.name
}


resource "aws_iam_role_policy" "ec2_workers_policy" {
  name = "ec2_workers_policy"
  role = aws_iam_role.ec2_workers_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      "Effect" : "Allow",
      "Action" : [
        "s3:ListBucket"
      ],
      "Resource" : "arn:aws:s3:::${var.bucket_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        "Effect" : "Allow"
        "Action" : [
          "elasticloadbalancing:DescribeTargetHealth",
          "logs:FilterLogEvents",
          "ssm:PutParameter",
          "elasticloadbalancing:DescribeListeners",
          "ec2:DescribeNatGateways",
          "ec2:DescribeInstances",
          "elasticloadbalancing:DescribeListenerAttributes",
          "ec2:DescribeNetworkInterfaces",
          "ecr:Pull"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "workers_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_workers_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.ec2_workers_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "workers_ec2_container_registry_read_only" {
  role       = aws_iam_role.ec2_workers_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "workers_eks_cni_policy" {
  role       = aws_iam_role.ec2_workers_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
