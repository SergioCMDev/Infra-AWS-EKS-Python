# =============================================
# ALB SG
# =============================================

resource "aws_security_group" "alb_access_sg" {
  name        = "${local.env}-alb-access-sg"
  description = "Allow http/https traffic to alb"
  vpc_id      = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = "2m"
  }

  tags = {
    Name = "${local.env}-alb-access-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_access_sg_ingress_internet" {
  for_each = toset(["80", "443"])

  security_group_id = aws_security_group.alb_access_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_workers" {
  for_each = toset(["5000"])

  security_group_id            = aws_security_group.alb_access_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "ALB egress to workers"
  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"
}

# =============================================
#  SSM ENDPOINTS RULES
# =============================================

resource "aws_security_group" "ssm_endpoints_sg" {
  name        = "${local.env}-vpce-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "SG for VPC Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "ssm_from_workers_https" {
  security_group_id            = aws_security_group.ssm_endpoints_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Allow HTTPS traffic from Workers to VPC Endpoints"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ssm_from_github_worker_https" {
  security_group_id            = aws_security_group.ssm_endpoints_sg.id
  referenced_security_group_id = aws_security_group.github_runner_sg.id

  description = "Allow HTTPS traffic from github runner to VPC Endpoints"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
