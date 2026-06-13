output "vpc_id" {
  value = aws_vpc.pxc_vpc.id
}

output "public_subnet_az1" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_subnet_az2" {
  value = aws_subnet.public_subnet_az2.id
}

output "db_subnet_az1" {
  value = aws_subnet.db_subnet_az1.id
}

output "db_subnet_az2" {
  value = aws_subnet.db_subnet_az2.id
}

output "db_subnet_az3" {
  value = aws_subnet.db_subnet_az3.id
}

output "pxc_security_group" {
  value = aws_security_group.pxc_sg.id
}

output "pxc1_private_ip" {
  value = aws_instance.pxc1.private_ip
}

output "pxc2_private_ip" {
  value = aws_instance.pxc2.private_ip
}

output "pxc3_private_ip" {
  value = aws_instance.pxc3.private_ip
}

output "proxysql1_public_ip" {
  value = aws_instance.proxysql1.public_ip
}

output "proxysql2_public_ip" {
  value = aws_instance.proxysql2.public_ip
}