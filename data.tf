#------------------------------------------------
## get asw_default_tags
#------------------------------------------------
data "aws_default_tags" "current" {}

#------------------------------------------------
## get first_public_subnet
#------------------------------------------------
data "aws_subnet" "first_public_subnet" {
    depends_on = [aws_subnet.public]
    #subnets in this vpc
    filter {
        name = "vpc-id"
        values = [aws_vpc.vpc.id]
    }
    #subnet with particular expression in their tag:Name
    filter {
        name   = "tag:Name"
        values = ["public-${var.public_subnet_config[0].az_name}-${local.name_suffix}"]
            }
 }

#------------------------------------------------
## get a list of public subnets
#------------------------------------------------
 data "aws_subnets" "selected_publics" {
    depends_on = [aws_subnet.public]
    
    filter {
        name = "vpc-id"
        values = [aws_vpc.vpc.id]
    }

    # Filter subnets by name containing "public"
    filter {
        name   = "tag:Name"
        values = ["*public*"] 
    }
}

#------------------------------------------------
## get a list of private subnets
#------------------------------------------------
 data "aws_subnets" "selected_privates" {
    depends_on = [aws_subnet.private]
    
    filter {
        name = "vpc-id"
        values = [aws_vpc.vpc.id]
    }

    # Filter subnets by name containing "private"
    filter {
        name   = "tag:Name"
        values = ["*private*"] 
    }
}

#------------------------------------------------
## get a list of VPCs
#------------------------------------------------
data "aws_vpcs" "existing_vpcs" {
  # Filter existing VPCs based on the specified name
  filter {
    name   = "tag:Name"
    values = ["vpc-${local.name_suffix}"]
  }
}