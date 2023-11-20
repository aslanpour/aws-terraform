
#---------------------------------
## create VPC
#---------------------------------
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "vpc-${local.name_suffix}"
  }
}

#---------------------------------
## create public subnets
#---------------------------------
resource "aws_subnet" "public" {
#iterate over a list of objects: https://stackoverflow.com/a/58607244/14167325
  for_each = {for subnet in var.public_subnet_config: subnet.cidr_block => subnet} #cidr_block is the  unique key
  availability_zone = each.value.az_name
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  map_public_ip_on_launch = true
  tags = {
    Name = "public-${each.value.az_name}-${local.name_suffix}"
  }
}

#---------------------------------
## create private subnets
#---------------------------------
resource "aws_subnet" "private" {
#iterate over a list of objects: https://stackoverflow.com/a/58607244/14167325
  for_each = {for subnet in var.private_subnet_config: subnet.cidr_block => subnet} #cidr_block is the unique key
  availability_zone = each.value.az_name
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  map_public_ip_on_launch = false
  tags = {
    Name = "private-${each.value.az_name}-${local.name_suffix}"
  }
}

#---------------------------------
## create internet gateway
#---------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Name = "igw-${local.name_suffix}"
  }
}

#---------------------------------
## create public route table
#---------------------------------
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "public-${local.name_suffix}"
    }
}

#link public route table to igw
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#link public subnets to public route table
resource "aws_route_table_association" "public_rt_association" {
  for_each = {for subnet in var.public_subnet_config: subnet.cidr_block => subnet}
  route_table_id = aws_route_table.public.id
  # how to reference resource instances created by for_each https://stackoverflow.com/questions/63641187/terraform-referencing-resources-created-in-for-each-in-another-resource
  subnet_id = aws_subnet.public[each.key].id
}

#---------------------------------
## create private route table 
#---------------------------------
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "private-${local.name_suffix}"
    }
}

#link subnets to route table
resource "aws_route_table_association" "private_rt_association" {
    for_each = {for subnet in var.private_subnet_config: subnet.cidr_block => subnet}
    route_table_id = aws_route_table.private.id
    # how to reference resource instances created by for_each https://stackoverflow.com/questions/63641187/terraform-referencing-resources-created-in-for-each-in-another-resource
    subnet_id = aws_subnet.private[each.key].id
}


#---------------------------------
## create nat gateway in public subnets and a route to it for use by private subnets
#---------------------------------
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = data.aws_subnet.first_public_subnet.id
  #recommended by Terraform
  depends_on = [aws_internet_gateway.igw]

  tags = {
      Name        = "nat_gateway-${local.name_suffix}"
    }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc" 
  tags = {
    Name = "nat_gateway-${local.name_suffix}"
  }
}

#Note that the default route, mapping the VPC's CIDR block to "local", is created implicitly and cannot be specified.
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route#argument-reference

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id             = aws_nat_gateway.nat_gateway.id
}
