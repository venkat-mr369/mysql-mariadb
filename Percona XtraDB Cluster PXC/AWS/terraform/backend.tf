terraform {
  backend "s3" {
    bucket         = "pxc-tfstate-102882775921"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}