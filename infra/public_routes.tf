resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.env}-route_table"
  }
}

resource "aws_route_table_association" "public_route_table" {
  count = length(local.public_nets_cidr)

  subnet_id      = aws_subnet.public_net[count.index].id
  route_table_id = aws_route_table.public_route.id
}
