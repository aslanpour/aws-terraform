#---------------------------------
## create security group for ec2 instances (web servers)
#---------------------------------
resource "aws_security_group" "ec2" {
    name = "ec2-${local.name_suffix}"
    description = "Allow http (only from LB), ssh and ping from anywhere"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.lb.id] # to ensure that only requests coming from any source associated with the the aws_security_group.lb are accepted.
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"] 
    }
    # ICMP code to allow a ping echo
    ingress {
        from_port = 8
        to_port = 0
        protocol = "icmp"
        cidr_blocks = ["10.0.0.0/16"] 
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ec2-${local.name_suffix}"
    }
}

#---------------------------------
## create security group for load balancer
#---------------------------------
resource "aws_security_group" "lb" {
    name = "lb-${local.name_suffix}"
    description = "Allow 80 from anywhere"
    vpc_id = aws_vpc.vpc.id
    ingress{
        description = "Allow 80 from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "lb-${local.name_suffix}"
    }
}

#---------------------------------
## create security group for bastion host
#---------------------------------
resource "aws_security_group" "bastion" {
    name = "bastion-${local.name_suffix}"
    description = "Allow SSH and ping from anywhere"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "bastion-${local.name_suffix}"
    }
}

#---------------------------------
## create security group for private ec2 instances 
#---------------------------------
resource "aws_security_group" "ec2_private" {
    name = "ec2-private-${local.name_suffix}"
    description = "Allow http, ssh and ping from anywhere"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.vpc_cidr_block] 
    }
    # ICMP code to allow a ping echo
    ingress {
        from_port = 8
        to_port = 0
        protocol = "icmp"
        cidr_blocks = [var.vpc_cidr_block] 
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ec2-private-${local.name_suffix}"
    }
}
