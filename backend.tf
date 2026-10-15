terraform {
    backend "s3" {
        bucket = "aws-environment-terraform"
        key = "AWS-environment-with-Terraform/terraform.tfstate"
        region = "us-east-1"
        encrypt = "true"
    }
}