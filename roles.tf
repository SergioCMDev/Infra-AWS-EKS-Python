resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_eks_cni_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# =============================================
# SSM ENDPOINTS
# =============================================


# Endpoint para SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private_net[*].id
  security_group_ids = [aws_security_group.ssm_endpoints_sg.id]

  private_dns_enabled = true
  tags = {
    Name = "${local.env}-ssm-endpoint"
  }
}

# Endpoint para EC2 Messages
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private_net[*].id
  security_group_ids = [aws_security_group.ssm_endpoints_sg.id]

  private_dns_enabled = true
  tags = {
    Name = "${local.env}-ec2-messages-endpoint"
  }
}

# Endpoint para SSM Messages (comunicación de agent)
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private_net[*].id
  security_group_ids = [aws_security_group.ssm_endpoints_sg.id]

  private_dns_enabled = true
  tags = {
    Name = "${local.env}-ssm-messages-endpoint"
  }
}
