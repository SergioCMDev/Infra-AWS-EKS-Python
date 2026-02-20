resource "aws_subnet" "private_net" {
  count = length(var.private_nets_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_nets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                          = "${var.env}-private_net_${count.index}_${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
