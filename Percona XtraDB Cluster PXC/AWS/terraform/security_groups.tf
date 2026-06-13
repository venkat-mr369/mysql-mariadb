resource "aws_security_group" "pxc_sg" {

  name        = "pxc-security-group"
  description = "Percona XtraDB Cluster Security Group"

  vpc_id = aws_vpc.pxc_vpc.id

  #################################################
  # SSH
  #################################################

  ingress {

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  #################################################
  # MySQL
  #################################################

  ingress {

    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # SST
  #################################################

  ingress {

    from_port = 4444
    to_port   = 4444
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # Galera Replication
  #################################################

  ingress {

    from_port = 4567
    to_port   = 4567
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # IST
  #################################################

  ingress {

    from_port = 4568
    to_port   = 4568
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # ProxySQL Admin
  #################################################

  ingress {

    from_port = 6032
    to_port   = 6032
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # ProxySQL Client
  #################################################

  ingress {

    from_port = 6033
    to_port   = 6033
    protocol  = "tcp"

    cidr_blocks = ["10.10.0.0/16"]
  }

  #################################################
  # Outbound
  #################################################

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  #################################################
  # Tags
  #################################################

  tags = {

    Name        = "pxc-sg"
    Environment = "prod"
  }
}