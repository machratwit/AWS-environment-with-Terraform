terraform {
  backend "s3" {
    bucket  = "aws-environment-terraform"
    key     = "aws-environment/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}