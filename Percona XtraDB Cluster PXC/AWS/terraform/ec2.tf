resource "aws_instance" "pxc1" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  subnet_id                   = aws_subnet.db_subnet_az1.id
  associate_public_ip_address = false

  key_name = aws_key_pair.pxc_key.key_name

  vpc_security_group_ids = [
    aws_security_group.pxc_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  user_data = file("${path.module}/scripts/bootstrap-pxc.sh")

  root_block_device {

    volume_size = 10
    volume_type = "gp3"

    tags = {
      Name = "pxc1-root"
    }
  }

  tags = {
    Name = "pxc-node1"
    Role = "PXC"
  }
}

resource "aws_instance" "pxc2" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  subnet_id                   = aws_subnet.db_subnet_az2.id
  associate_public_ip_address = false

  key_name = aws_key_pair.pxc_key.key_name

  vpc_security_group_ids = [
    aws_security_group.pxc_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  user_data = file("${path.module}/scripts/bootstrap-pxc.sh")

  root_block_device {

    volume_size = 10
    volume_type = "gp3"

    tags = {
      Name = "pxc2-root"
    }
  }

  tags = {
    Name = "pxc-node2"
    Role = "PXC"
  }
}


resource "aws_instance" "pxc3" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  subnet_id                   = aws_subnet.db_subnet_az3.id
  associate_public_ip_address = false

  key_name = aws_key_pair.pxc_key.key_name

  vpc_security_group_ids = [
    aws_security_group.pxc_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  user_data = file("${path.module}/scripts/bootstrap-pxc.sh")

  root_block_device {

    volume_size = 10
    volume_type = "gp3"

    tags = {
      Name = "pxc3-root"
    }
  }

  tags = {
    Name = "pxc-node3"
    Role = "PXC"
  }
}

resource "aws_instance" "proxysql1" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public_subnet_az1.id
  associate_public_ip_address = true

  key_name = aws_key_pair.pxc_key.key_name

  vpc_security_group_ids = [
    aws_security_group.pxc_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  user_data = file("${path.module}/scripts/bootstrap-proxysql.sh")

  root_block_device {

    volume_size = 10
    volume_type = "gp3"

    tags = {
      Name = "proxysql1-root"
    }
  }

  tags = {
    Name = "proxysql1"
    Role = "ProxySQL"
  }

}

resource "aws_instance" "proxysql2" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public_subnet_az2.id
  associate_public_ip_address = true

  key_name = aws_key_pair.pxc_key.key_name

  vpc_security_group_ids = [
    aws_security_group.pxc_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  user_data = file("${path.module}/scripts/bootstrap-proxysql.sh")

  root_block_device {

    volume_size = 10
    volume_type = "gp3"

    tags = {
      Name = "proxysql2-root"
    }
  }

  tags = {
    Name = "proxysql2"
    Role = "ProxySQL"
  }

}