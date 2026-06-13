resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {
    Name = "pxc-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {

  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "pxc-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.pxc_igw
  ]
}