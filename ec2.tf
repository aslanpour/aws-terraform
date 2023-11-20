#---------------------------------
## create launch config for ec2 instances (web servers)
## attaches the load balancer security group so it only allows traffic from the load balancer.
#---------------------------------
resource "aws_launch_configuration" "launch_config" {
    name_prefix     = var.asg_launch_config.name_prefix
    image_id        = var.asg_launch_config.image_id
    instance_type   = var.asg_launch_config.instance_type
    user_data       = file("${var.asg_launch_config.user_data_file_path}")
    security_groups = [aws_security_group.ec2.id]
    key_name = aws_key_pair.web.key_name
    associate_public_ip_address = var.asg_launch_config.associate_public_ip_address
    lifecycle {
        create_before_destroy = true
    }
}

#---------------------------------
## create bastion host 
#---------------------------------
resource "aws_instance" "bastion" {
    ami = var.bastion_ami
    instance_type = var.bastion_instance_type
    vpc_security_group_ids = [aws_security_group.bastion.id]
    subnet_id = data.aws_subnet.first_public_subnet.id
    associate_public_ip_address = true
    key_name = aws_key_pair.bastion.key_name
    tags = {
        Name = "bastion"
    }
}

#---------------------------------
## register ssh key pair for bastion host
#---------------------------------
resource "aws_key_pair" "bastion" {
    key_name = "bastion"
    public_key = var.key_pair_public
    tags = {
        Name = "bastion"
    }
}

#---------------------------------
## register ssh key pair for web-server host
#---------------------------------
resource "aws_key_pair" "web" {
    key_name = "web"
    public_key = var.key_pair_public
    tags = {
        Name = "web"
    }
}