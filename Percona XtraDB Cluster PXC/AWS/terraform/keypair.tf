resource "aws_key_pair" "pxc_key" {

  key_name = "pxc-key"

  public_key = file("C:/Users/venkat/.ssh/id_rsa.pub")
}