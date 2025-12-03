resource "aws_security_group" "cluster_eks" {
  name        = "${local.env}-cluster-eks-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group of cluster"

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = "2m"
  }

  tags = {
    Name = "${local.env}-cluster-eks-sg"
  "kubernetes.io/cluster/${local.cluster_name}" = "shared" }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_eks_from_workers" {
  for_each = toset(["443", "9443"])

  security_group_id            = aws_security_group.cluster_eks.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"
  description = "Allow traffic from workers to cluster"
}

resource "aws_vpc_security_group_egress_rule" "cluster_egress" {
  security_group_id = aws_security_group.cluster_eks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "cluster_egress-egress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_eks_from_github_runner" {
  security_group_id            = aws_security_group.cluster_eks.id
  referenced_security_group_id = aws_security_group.github_runner_sg.id

  description = "Allow conection from github runner"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
