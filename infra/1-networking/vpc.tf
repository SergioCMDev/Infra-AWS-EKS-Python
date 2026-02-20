resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name                                          = "${var.env}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"

  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}
