

#---------------------------------
## create a NACL for public subnets (allow HTTP and SSH)
#---------------------------------
resource "aws_network_acl" "public" {
    vpc_id = aws_vpc.vpc.id

    #open egress for port 80, only for use by the NAT gateway (not needed for the web instances, since they return response by one of the ephemeral ports)
    #Allows outbound IPv4 HTTP traffic from the subnet to the internet.
    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    egress {
        protocol   = "tcp"
        rule_no    = 120
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 22
        to_port    = 22
    }
    #Allows outbound traffic through ephemeral ports
    egress {
        protocol   = "tcp"
        rule_no    = 110
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }
    egress {
        #How to enable ICMP 
        # https://stackoverflow.com/questions/65673015/from-port-and-to-port-values-for-icmp-protocol-ingress-rule-aws-security-group-r
        # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl
        protocol   = "icmp"
        rule_no    = 105
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 8
        to_port    = 0
        icmp_type = -1
        icmp_code = -1
    }
    #Allows inbound HTTP traffic from any IPv4 address.
    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    #Allows inbound SSH traffic from your home network's public IPv4 address range (over the internet gateway).
    ingress {
        protocol   = "tcp"
        rule_no    = 60
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 22
        to_port    = 22
    }
    ingress {
        protocol   = "tcp"
        rule_no    = 40
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }
    ingress {
        protocol   = "icmp"
        rule_no    = 20
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 8
        to_port    = 0
        icmp_type = -1
        icmp_code = -1
    }
  tags = {
    Name = "public"
  }
}

resource "aws_network_acl_association" "public" {
    for_each = {for subnet in var.public_subnet_config: subnet.cidr_block => subnet}
    #for_each = toset([for subnet in aws_subnet.public : subnet.id])
    #for_each = toset(data.aws_subnets.selected_publics.ids)

    network_acl_id = aws_network_acl.public.id
    subnet_id      = aws_subnet.public[each.key].id
}


#---------------------------------
## create a NACL for private subnets (allow HTTP and SSH)
#---------------------------------
resource "aws_network_acl" "private" {
    vpc_id = aws_vpc.vpc.id

    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 22
        to_port    = 22
    }
    egress {
        protocol   = "tcp"
        rule_no    = 180
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    egress {
        protocol   = "tcp"
        rule_no    = 160
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }
    egress {
        protocol   = "icmp"
        rule_no    = 140
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 8
        to_port    = 0
        icmp_type = -1
        icmp_code = -1
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 22
        to_port    = 22
    }
    ingress {
        protocol   = "tcp"
        rule_no    = 80
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    ingress {
        protocol   = "tcp"
        rule_no    = 60
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }
    ingress {
        protocol   = "icmp"
        rule_no    = 40
        action     = "allow"
        cidr_block = var.vpc_cidr_block
        from_port  = 8
        to_port    = 0
        icmp_type = -1
        icmp_code = -1
    }
  tags = {
    Name = "private"
  }
}

resource "aws_network_acl_association" "private" {
    for_each = {for subnet in var.private_subnet_config: subnet.cidr_block => subnet}

    #for_each = toset([for subnet in aws_subnet.private : subnet.id])
    #for_each = toset(data.aws_subnets.selected_privates.ids)

    network_acl_id = aws_network_acl.private.id
    subnet_id      = aws_subnet.private[each.key].id
    
}

