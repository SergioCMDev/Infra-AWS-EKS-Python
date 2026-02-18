# =============================================
# WORKERS (EC2) RULES
# =============================================

resource "aws_security_group" "ec2_sg" {
  name        = "${local.env}-ec2-access-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group of workers"

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = "2m"
  }

  tags = {
    Name = "${local.env}-ec2-access-sg"
  "kubernetes.io/cluster/${local.cluster_name}" = "shared" }
}

# Pod to Pod communication
resource "aws_vpc_security_group_egress_rule" "workers_pod_to_pod_http" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Pod to pod HTTP"
  from_port   = 8000
  to_port     = 8999
  ip_protocol = "tcp"
}
###################################################################
# AWS VPC CNI
resource "aws_vpc_security_group_egress_rule" "workers_cni_grpc" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "AWS VPC CNI gRPC"
  from_port   = 50051
  to_port     = 50051
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_cni_grpc" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "AWS VPC CNI gRPC"
  from_port   = 50051
  to_port     = 50051
  ip_protocol = "tcp"
}
###################################################################

# kube-proxy
resource "aws_vpc_security_group_egress_rule" "workers_kube_proxy" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "kube-proxy workers"
  from_port   = 10256
  to_port     = 10256
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_kube_proxy" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "kube-proxy health check"
  from_port   = 10256
  to_port     = 10256
  ip_protocol = "tcp"
}
###################################################################
# Kubelet
resource "aws_vpc_security_group_egress_rule" "workers_kubelet" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Kubelet API workers"
  from_port   = 10250
  to_port     = 10250
  ip_protocol = "tcp"
}

# Kubelet - Para que kube-proxy y otros componentes puedan comunicarse
resource "aws_vpc_security_group_ingress_rule" "workers_kubelet" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Kubelet API between workers"
  from_port   = 10250
  to_port     = 10250
  ip_protocol = "tcp"
}

###################################################################

resource "aws_vpc_security_group_egress_rule" "workers_coredns_udp" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "CoreDNS UDP workers"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_coredns_udp" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "CoreDNS UDP workers"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}

###################################################################
# CoreDNS
resource "aws_vpc_security_group_egress_rule" "workers_coredns_tcp" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "CoreDNS TCP workers"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_coredns_tcp" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "CoreDNS TCP between workers"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
}

###################################################################


resource "aws_vpc_security_group_egress_rule" "workers_dns_udp" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "DNS UDP internet"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}


resource "aws_vpc_security_group_egress_rule" "workers_dns_tcp" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "DNS TCP internet"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
}
###################################################################

resource "aws_vpc_security_group_egress_rule" "workers_http" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "HTTP internet (package repos)"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "workers_https" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  description = "HTTPS internet (registries, APIs)"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
###################################################################

resource "aws_vpc_security_group_egress_rule" "workers_to_api_server" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Workers cluster API server"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_pods_https" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_access_sg.id

  description = "ALB to pods HTTPS"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# HTTPS general para otros servicios en pods
resource "aws_vpc_security_group_ingress_rule" "cluster_to_pods_https" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Cluster to pods HTTPS"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}


resource "aws_vpc_security_group_ingress_rule" "alb_to_pods_5000" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_access_sg.id

  description = "ALB to pods port 5000"
  from_port   = 5000
  to_port     = 5000
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_pods_http" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_access_sg.id

  description = "ALB to pods HTTP"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Kubelet API - Control plane necesita hablar con kubelet en cada nodo
resource "aws_vpc_security_group_ingress_rule" "cluster_to_kubelet" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Cluster to kubelet API"
  from_port   = 10250
  to_port     = 10250
  ip_protocol = "tcp"
}

# Webhooks - Validating/Mutating webhooks (ALB Controller, cert-manager, etc.)
resource "aws_vpc_security_group_ingress_rule" "cluster_to_webhooks" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Cluster to admission webhooks (9443)"
  from_port   = 9443
  to_port     = 9443
  ip_protocol = "tcp"
}

# Metrics Server
resource "aws_vpc_security_group_ingress_rule" "cluster_to_metrics_server" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.cluster_eks.id

  description = "Cluster to metrics-server"
  from_port   = 4443
  to_port     = 4443
  ip_protocol = "tcp"
}


##########################################################################################
# ArgoCD Redis
resource "aws_vpc_security_group_egress_rule" "workers_pod_to_pod_redis" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Redis between workers egress"
  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_pod_to_pod_redis" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "Redis between workers ingress"
  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"
}

##########################################################################################
# ArgoCD Repo server
resource "aws_vpc_security_group_egress_rule" "workers_pod_to_pod_ArgoCD_repo_server" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "ArgoCD repo server workers egress"
  from_port   = 8081
  to_port     = 8081
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_pod_to_pod_ArgoCD_repo_server" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "ArgoCD repo server workers ingress"
  from_port   = 8081
  to_port     = 8081
  ip_protocol = "tcp"
}

##########################################################################################
# ArgoCD Repo server
resource "aws_vpc_security_group_egress_rule" "workers_pod_to_pod_ArgoCD_metrics" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "ArgoCD metrics egress"
  from_port   = 8084
  to_port     = 8084
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_pod_to_pod_ArgoCD_metrics" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "ArgoCD metrics ingress"
  from_port   = 8084
  to_port     = 8084
  ip_protocol = "tcp"
}


##########################################################################################
# TCP
resource "aws_vpc_security_group_egress_rule" "workers_tcp_ephimereal" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "TCP ephimereal"
  from_port   = 1025
  to_port     = 65535
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "workers_tcp_ephimereal" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id

  description = "TCP ephimereal"
  from_port   = 1025
  to_port     = 65535
  ip_protocol = "tcp"
}
