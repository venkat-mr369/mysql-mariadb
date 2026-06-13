resource "aws_vpc" "pxc_vpc" {

  cidr_block = "10.10.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "pxc-vpc"
    Environment = "prod"
  }
}
## Internet Gateway
resource "aws_internet_gateway" "pxc_igw" {

  vpc_id = aws_vpc.pxc_vpc.id

  tags = {
    Name = "pxc-igw"
  }
}