# Variable Definition Precendence (the last ones take the precendence)
# https://developer.hashicorp.com/terraform/language/values/variables#variable-definition-precedence
#-----------------
## Environment variables
## The terraform.tfvars file, if present.
## The terraform.tfvars.json file, if present.
## Any *.auto.tfvars or *.auto.tfvars.json files, processed in lexical order of their filenames.
## Any -var and -var-file options on the command line, in the order they are provided. (This includes variables set by a Terraform Cloud workspace.)

#------------------------------------------------
## aws configuration
#------------------------------------------------
variable "profile" {
  description = "Put your AWS CLI profile name. Type \"default\" if you have no especific profile. The value will not be shown since it is set as sensitive."
  type      = string
  sensitive = true
}

variable "target_region" {
  type      = string
  default   = "ap-southeast-2"
  sensitive = true
}

#------------------------------------------------
## vpc (a nat gateway will also be deployed in the first_public_subnet)
#------------------------------------------------
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_config" {
  type = list(object({
    cidr_block = string
    az_name    = string
  }))
  default = [
    {
      cidr_block = "10.0.1.0/24"
      az_name    = "ap-southeast-2a"
    },
    {
      cidr_block = "10.0.2.0/24"
      az_name    = "ap-southeast-2b"
    },
    {
      cidr_block = "10.0.3.0/24"
      az_name    = "ap-southeast-2c"
    },
  ]
}

variable "private_subnet_config" {
  type = list(object({
    cidr_block = string
    az_name    = string
  }))
  default = [
    {
      cidr_block = "10.0.101.0/24"
      az_name    = "ap-southeast-2a"
    },
    {
      cidr_block = "10.0.102.0/24"
      az_name    = "ap-southeast-2b"
    },
    {
      cidr_block = "10.0.103.0/24"
      az_name    = "ap-southeast-2c"
    },
  ]
}

#------------------------------------------------
##  tags and naming conventions
#------------------------------------------------
#use in a resource --> tags = var.common_tags
variable "common_tags" {
  description = "Common tags to set for resources (will be set for locals' common_tags and the provider's default_tags)"
  type        = map(string)
  nullable    = false
}

#------------------------------------------------
## ec2 instance config for web servers managed by ASG (they get deployed in the public subnets)
#------------------------------------------------
variable "asg_launch_config" {
  type = object({
    name_prefix = string
    image_id = string
    instance_type = string
    user_data_file_path = string
    associate_public_ip_address = bool
   })
  default = {
    name_prefix                 = "web-"
    image_id                    = "ami-0df4b2961410d4cff"
    instance_type               = "t2.micro"
    user_data_file_path         = "user-data.sh"
    associate_public_ip_address = true
  }
}

#------------------------------------------------
## ec2 instance config for bastion host and its key pair (it is automatically deployed to the first_public_subnet of the vpc)
#------------------------------------------------
variable "bastion_ami" {
  type = string
  default = "ami-0df4b2961410d4cff"
}

variable "bastion_instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_pair_public" {
  description = "Provide public key of your ssh key pair to be used for bastion hosts and web servers. The value will not be shown as it is set as sensitive."
  type        = string
  sensitive   = true
  nullable = false
}

#------------------------------------------------
## auto scaling
#------------------------------------------------
variable "asg" {
    type = object({
      name = string
      max_size = number
      min_size = number
      desired_capacity = number
    })
    default = {
        name = "web"
        max_size = 3
        min_size = 1
        desired_capacity = 2
    }
}

variable "asg_policy" {
    type = object({
        policy_type = string
        estimated_instance_warmup = number
    })
    default = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 30
    }
  }

variable "asg_policy_target_config_metric" {
  type    = string
  default = "ASGAverageCPUUtilization"
}

variable "asg_policy_target_config_value" {
  type    = number
  default = 80
}




