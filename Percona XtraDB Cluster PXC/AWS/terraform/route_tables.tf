resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.pxc_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.pxc_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.pxc_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public_assoc_az1" {

  subnet_id = aws_subnet.public_subnet_az1.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_az2" {

  subnet_id = aws_subnet.public_subnet_az2.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc_az1" {

  subnet_id = aws_subnet.db_subnet_az1.id

  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_az2" {

  subnet_id = aws_subnet.db_subnet_az2.id

  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_az3" {

  subnet_id = aws_subnet.db_subnet_az3.id

  route_table_id = aws_route_table.private_rt.id
}