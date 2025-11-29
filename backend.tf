terraform {
  required_version = ">= 1.0.0, < 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket               = "guestlist-tfstate-bucket"
    key                  = "terraform.tfstate"   
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "terraform-locks"     
    workspace_key_prefix = "envs"                
  }
}
