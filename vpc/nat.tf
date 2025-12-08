resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets[0].id # NAT Gateway in 1st public subnet

  tags = {
    Name = "nat-gateway"
  }
}
