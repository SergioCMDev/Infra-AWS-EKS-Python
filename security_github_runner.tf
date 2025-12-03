# =============================================
# SECURITY GROUPS FOR GITHUB RUNNER
# =============================================

resource "aws_security_group" "github_runner_sg" {
  name        = "${local.env}-github_runner_sg"
  description = "Allow http/https traffic to github runner"
  vpc_id      = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = "2m"
  }

  tags = {
    Name        = "github-actions-runner-sg"
    ManagedBy   = "Terraform"
    Environment = local.env
  }
}
resource "aws_vpc_security_group_egress_rule" "github_runner_https" {
  security_group_id = aws_security_group.github_runner_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "HTTPS for container registries, updates, APIs"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "github_runner_http" {
  security_group_id = aws_security_group.github_runner_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "HTTP for package repositories"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "github_runner_dns_udp" {
  security_group_id = aws_security_group.github_runner_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "DNS resolution (UDP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"

  tags = {
    Name = "github-runner-dns-udp-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "github_runner_dns_tcp" {
  security_group_id = aws_security_group.github_runner_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "DNS resolution (TCP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"

  tags = {
    Name = "github-runner-dns-tcp-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "github_runner_ntp" {
  security_group_id = aws_security_group.github_runner_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "NTP for time synchronization"
  from_port         = 123
  to_port           = 123
  ip_protocol       = "udp"

  tags = {
    Name = "github-runner-ntp-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "github_runner_to_ssm_endpoints" {
  security_group_id            = aws_security_group.github_runner_sg.id
  referenced_security_group_id = aws_security_group.ssm_endpoints_sg.id

  description = "Allow github runner to connect to VPC endpoints"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "github_runner_to_cluster_eks" {
  security_group_id            = aws_security_group.github_runner_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Allow github runner to connect to Cluster EKS"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
