resource "aws_route_table" "private_route" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${local.env}-private_route_table_${count.index}"
  }
}

resource "aws_route_table_association" "private_zone" {
  count = length(local.availability_zones)

  subnet_id      = aws_subnet.private_net[count.index].id
  route_table_id = aws_route_table.private_route[count.index].id
}
