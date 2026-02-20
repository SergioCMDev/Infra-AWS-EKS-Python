resource "aws_subnet" "public_net" {
  count = length(var.public_nets_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_nets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.env}-public_subnet_${count.index}_${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
