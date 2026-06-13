resource "aws_subnet" "db_subnet_az1" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "db-subnet-az1"
  }
}

resource "aws_subnet" "db_subnet_az2" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "db-subnet-az2"
  }
}

resource "aws_subnet" "public_subnet_az1" {

  vpc_id                  = aws_vpc.pxc_vpc.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1"
  }
}

resource "aws_subnet" "public_subnet_az2" {

  vpc_id                  = aws_vpc.pxc_vpc.id
  cidr_block              = "10.10.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2"
  }
}

resource "aws_subnet" "db_subnet_az3" {

  vpc_id            = aws_vpc.pxc_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "db-subnet-az3"
  }
}