resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr
  tags = {
    Name                                          = "${local.env}-vpc"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"

  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}
