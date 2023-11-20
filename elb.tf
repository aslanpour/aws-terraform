#improvements:
#integrate with WAF for DDoS protection
#integrated with Route 53 for better DNS
#integrate with Global Accelerator
#integrate with Config to provide visibility into its integration with other resources

#---------------------------------
## create an application load balancer (covering public subnets)
#---------------------------------
resource "aws_lb" "alb" {
    name = "alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lb.id]
    #either use subnets or subnet_mapping 
    subnets            = [for subnet in aws_subnet.public : subnet.id]

    tags = {
        Name = "alb"
    }
}

#---------------------------------
## create a target_group for application load balancer (+ health check)
#---------------------------------
resource "aws_lb_target_group" "alb_tg" {
    name = "alb-tg"
    port = 80   # The port on which targets receive traffic. Only applies to target_type = instance, ip or alb, not lambda.
    target_type = "instance"  # or ip, lambda, alb
    vpc_id = aws_vpc.vpc.id
    load_balancing_algorithm_type = "round_robin"     # default is round_robin. Can also be "least_outstanding_requests"
    protocol = "HTTP"   # options are GENEVE, HTTP, HTTPS, TCP, TCP_UDP, TLS, or UDP. Not for target_type = lambda.
    protocol_version = "HTTP1"  # default is HTTP1.
    slow_start = 0  # default is 0. Options 30-900 seconds. Amount time for target to warm up before the load balancer sends them a full share of requests.

    #    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check
    health_check {
        enabled = true
        interval = 30   # Amount of time between health checks for an instance. default is 30 seconds. Range is 5-300
        path = "/"
        port = 80
        protocol = "HTTP"
        healthy_threshold = 3   # Number of consecutive health check successes required before considering a target healthy. The range is 2-10. Defaults to 3.
        timeout = 6 # Amount of time, in seconds, during which no response from a target means a failed health check. The range is 2–120 seconds. For target groups with a protocol of HTTP, the default is 6 seconds.
        unhealthy_threshold = 3 # Number of consecutive health check failures required before considering a target unhealthy. The range is 2-10. Defaults to 3.
        matcher = "200-299" # Response codes to use when checking for a healthy responses from a target.
    }
    tags = {
        Name = "alb_tg"
    }
}

#---------------------------------
## create a listener for application load balancer that connects alb and alb_tg
#---------------------------------
resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.alb.arn
    port = "80" # Port on which the load balancer is listening. 
    protocol = "HTTP"   # Protocol for connections from clients to the load balancer. For Application Load Balancers, valid values are HTTP and HTTPS, with a default of HTTP.
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.alb_tg.id
    }
    tags = {
        Name = "listener"
    }
}


#---------------------------
# Below config is not applicable when there is an auto scaling group to handle the instances.
# Reason:
# https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg
# While you can use an aws_lb_target_group_attachment resource to directly associate an EC2 instance or other target type with the target group, 
# the dynamic nature of instances in an ASG makes that hard to maintain in configuration. 
# Instead, this configuration links your Auto Scaling group with the target group using the aws_autoscaling_attachment resource. 
# This allows AWS to automatically add and remove instances from the target group over their lifecycle.
#------------------------
/*
#Provides the ability to register instances and containers with an Application Load Balancer (ALB) or Network Load Balancer (NLB) target group.
resource "aws_lb_target_group_attachment" "web-tg-attach" {
    provider = aws.region-test
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id = aws_instance.web-instance.id
    port = 80
}
*/