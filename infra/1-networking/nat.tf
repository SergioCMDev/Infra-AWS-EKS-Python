resource "aws_eip" "nat" {
  count = length(var.availability_zones)

  domain = "vpc"
  tags = {
    Name = "${var.env}-nat_${count.index}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_net[count.index].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.env}-nat_gateway_${count.index}"
  }
}
