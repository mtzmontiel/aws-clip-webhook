# aws api gateway that receives payload and stores to dynamo db
provider "aws" {
  region  = "us-east-1"
  profile = var.profile
}


data "aws_caller_identity" "current" {

}



