#Configure Terraform to use your AWS account in one of the following ways.
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication
#make sure to set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables for the AWS provider.
#or define shared_credentials_file = "/path/to/aws_credentials" in the aws provider section.
#hardcoding the access_key and secret_key  in the aws provider section is also an option, but not recommanded.

#check the stored state file for Terraform version that generated the state.
# grep -e '"version"' -e '"terraform_version"' terraform.tfstate

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      version = ">= 2.1.2"
    }
  }
  # Any Terraform v0.15.x, but not v1.0 or later
  # https://developer.hashicorp.com/terraform/tutorials/configuration-language/versions
  required_version = "~> 1.6.0"
}



provider "aws" {
  profile = var.profile
  region  = var.target_region
  #if alias is defined, the default_tags would work, as mentioned in https://stackoverflow.com/questions/76078122/terraform-default-tags-block-not-setting-tags-in-aws-resources
  # The default_tags block applies tags to all resources managed by this provider no matter if they define tags or not, except for the Auto Scaling groups (ASG).
  #use by "var.default_tags"
  default_tags {
    tags = local.common_tags
  }
}
