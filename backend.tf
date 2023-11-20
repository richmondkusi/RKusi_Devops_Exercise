
terraform {
  backend "s3" {
    bucket = "nbs-devops-interviews-terraform"
    key    = "RichKusi/path/key"
    region = "eu-west-1"
  }
}
