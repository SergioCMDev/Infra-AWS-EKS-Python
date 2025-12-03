resource "aws_subnet" "private_net" {
  count = length(local.private_nets_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_nets_cidr[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name                                          = "${local.env}-private_net_${count.index}_${local.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
