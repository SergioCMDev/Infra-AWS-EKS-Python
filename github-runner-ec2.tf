resource "aws_instance" "github_runner" {
  ami                         = local.ami_image
  instance_type               = local.github_runner_instance_type
  subnet_id                   = aws_subnet.private_net[0].id
  vpc_security_group_ids      = [aws_security_group.github_runner_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/${local.scripts_folder}/github_runner_starting_script.sh", {
    repo_name                 = local.repo_name
    repo_user                 = local.repo_user
    token                     = local.token
    s3_bucket_name            = local.bucket_name
    runner_version            = var.runner_version
    runner_name               = local.runner_name
    runner_labels             = var.runner_labels
    blue_green_updater_script = base64encode(file("${path.module}/${local.scripts_folder}/blue-green-updater.sh"))
    configure_eks_script      = base64encode(local_file.configure_eks.content)
  })

  iam_instance_profile = aws_iam_instance_profile.github_runner_profile.name

  tags = {
    Name = "${local.env}-github_runner"
  }

  depends_on = [aws_eks_cluster.main]
}

resource "aws_iam_role" "ec2_github_runner_role" {
  name = "ec2_github_runner_role"

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

resource "aws_iam_role_policy" "ec2_github_runner_policy" {
  name = "ec2_github_runner_policy"
  role = aws_iam_role.ec2_github_runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      "Effect" : "Allow",
      "Action" : [
        "s3:ListBucket"
      ],
      "Resource" : "arn:aws:s3:::${local.bucket_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : "arn:aws:s3:::${local.bucket_name}/*"
      },
      {
        "Effect" : "Allow"
        "Action" : [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeClusterVersions"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_runner_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "github_runner_profile" {
  name = "ec2-github_runner-profile"
  role = aws_iam_role.ec2_github_runner_role.name
}
