resource "aws_subnet" "public_net" {
  count = length(local.public_nets_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.public_nets_cidr[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name                                          = "${local.env}-public_subnet_${count.index}_${local.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
