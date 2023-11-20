#---------------------------------
## create auto scaling group (covering public subnets)
#---------------------------------
resource "aws_autoscaling_group" "web" {
    depends_on = [aws_launch_configuration.launch_config]
    name                = var.asg.name
    max_size            = var.asg.max_size
    min_size            = var.asg.min_size
    desired_capacity    = var.asg.desired_capacity
    vpc_zone_identifier = data.aws_subnets.selected_publics.ids
    launch_configuration = aws_launch_configuration.launch_config.name
    
    # not sure about this!
    # https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-check-grace-period.html?icmpid=docs_ec2as_help_panel
    # Turn on Elastic Load Balancing health check (recommended by AWS)
    # ELB monitors instances and if it reports an unhealthy instance, the ASG replaces it on its next preiodic check.
    #health_check_type         = "ELB"   # "EC2" or "ELB"

    lifecycle {
        ignore_changes = [load_balancers, target_group_arns]
    }
    # https://developer.hashicorp.com/terraform/tutorials/aws/aws-default-tags
    # automatic tagging by aws_default_tags do not apply to instances managed by autoscaling_group.
    # after terraform apply, you may verify assigned tags to the ASG by this
    # aws autoscaling describe-tags --region "ap-southeast-2" --filters "Name=auto-scaling-group,Values=$(terraform output asg_id)"
    # here is the workaround.
    dynamic "tag" {
        for_each = data.aws_default_tags.current.tags
        content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
        }
    }
}

#---------------------------------
## create auto scaling policy
#---------------------------------
resource "aws_autoscaling_policy" "policy" {
  name                   = "policy"
  policy_type            = var.asg_policy.policy_type
  estimated_instance_warmup = var.asg_policy.estimated_instance_warmup
  autoscaling_group_name = aws_autoscaling_group.web.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.asg_policy_target_config_metric
    }
    target_value = var.asg_policy_target_config_value
  }
}


#---------------------------------
## attach a load balancer to an auto scaling group
#---------------------------------
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
#https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg

resource "aws_autoscaling_attachment" "alb_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  lb_target_group_arn    = aws_lb_target_group.alb_tg.arn
}
