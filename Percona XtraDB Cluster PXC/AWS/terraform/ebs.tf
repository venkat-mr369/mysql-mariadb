resource "aws_ebs_volume" "pxc1_data" {

  availability_zone = aws_instance.pxc1.availability_zone

  size = 25

  type = "gp3"

  tags = {
    Name = "pxc1-data"
  }
}

resource "aws_ebs_volume" "pxc2_data" {

  availability_zone = aws_instance.pxc2.availability_zone

  size = 25

  type = "gp3"

  tags = {
    Name = "pxc2-data"
  }
}

resource "aws_ebs_volume" "pxc3_data" {

  availability_zone = aws_instance.pxc3.availability_zone

  size = 25

  type = "gp3"

  tags = {
    Name = "pxc3-data"
  }
}

resource "aws_volume_attachment" "pxc1_attach" {

  device_name = "/dev/sdf"

  volume_id = aws_ebs_volume.pxc1_data.id

  instance_id = aws_instance.pxc1.id
}

resource "aws_volume_attachment" "pxc2_attach" {

  device_name = "/dev/sdf"

  volume_id = aws_ebs_volume.pxc2_data.id

  instance_id = aws_instance.pxc2.id
}

resource "aws_volume_attachment" "pxc3_attach" {

  device_name = "/dev/sdf"

  volume_id = aws_ebs_volume.pxc3_data.id

  instance_id = aws_instance.pxc3.id
}