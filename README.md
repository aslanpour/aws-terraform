
# A Terraform template to deploy an application stack on AWS

The goal of this project is to define a Terraform template that creates an application stack wherein a web application can serve incoming requests with the help of a load balancer, backed by an auto-scaler automatically, securely, and reliably. The operation staff should also be able to access relevant instances securely.

Here a design of the system and then the implementation thereof in five steps are provided.

## Design
![Application Stack Design](https://drive.google.com/file/d/1T1o9prGmQa_f9cNp7WROYoOfMQXaNHA_/view?usp=sharing)


## Implementation
Here a description of the Terraform code to implement the designed system. 

### Task 0: Terraform Configuration
The `terraform.tf' file is created to configure the Terraform provider to be 'aws'. It also is set to use particular versions of the provider and Terraform controller. 
The provider configuration sets three parameters received from defined variables.

 - `region`: defines the region to which the VPC is created. It receives its value from the `target-region` variable. The default is `ap-southeast-2` and it is set as sensitive to not show in the output.
 - `profile`: The AWS CLI is directed to use your particular profile if you have one. Terraform will prompt for its value as input. It is set as sensitive.
- `default_tags` The default tags that will be applied to all resources managed by this provider. ASG resources are not included. If the input variables have a variable named `common_tags`, those values will be used for this parameter and later on for ASG resources. Note: the `common_tags` variable must have these tags defined: `Project`, `Environment`, and `Owner`. Note that if  an alias is defined for the provider, the automatic tagging might not work [[Ref. link]](https://stackoverflow.com/questions/76078122/terraform-default-tags-block-not-setting-tags-in-aws-resources).

A `main.tf` file is also created to define `locals` which for now only sets `commong_tags` based on the given value of `var.common_tags`. It also defines a `name_suffix` to be used for naming resources.

Lastly, you need to authenticate to your AWS account in one of the ways mentioned [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

## Task 1: Network
All the network configuration is defined in `network.tf` file.
 1. A VPC in the `ap-southeast-2` region.
It creates a VPC resource as `vpc` using the `vpc_cidr_block` variable. The `variables.tf` sets `10.0.0.0/16` for the CIDR block.
 2. Three public and three private subnets in different availability zones.
 It creates three (unless specified otherwise by `public_subnet_config` variable) public subnets in different AZs and enables `map_public_ip_on_launch` for them. Three private subnets are also created as specified by `private_subnet_config`. The variable must conform to this style:
 ```
 type = list(object({
    cidr_block = string
    az_name    = string
  }))
 ```
 The default values set in `variables.tf` define `10.0.1.0/24`, `10.0.2.0/24` and `10.0.1.0/24` in three AZs of `ap-southeast-2a`, `ap-southeast-2b`, and `ap-southeast-2c`, correspondingly for public subnets. 
 It sets a different range of CIDR blocks for private subnets as `10.0.101.0/24`, `10.0.102.0/24`, and `10.0.103.0/24`.
 
 3. An Internet Gateway
 4. A public and a private router.
 It creates a public router that has a route to the Internet Gateway and associates all public subnets to it. 
 It also creates a private router for local traffic and associates all private subnets to it. 
 5. A Nat Gateway in each of the public subnets.
It creates a Nat Gateway in the public subnets and creates a route in the private router to direct requests that are looking for internet access to it.


### Task 2: Security
This section shows the configuration for AWS Security Group in the `sg.tf` file and NACL `nacl.tf` file.

**Security Groups**. 

 - *Load Balancer Security Group*: A security group for the load balancer is created to only allow HTTP requests from anywhere.
 - *Web Server Security Group*: A security group for the web servers is created to allow HTTP requests (only from the load balancer), SSH (from the internal network), and ICMP (from the internal network). With this limited HTTP access, the web servers are secured so that no request can directly enter the web server, without being sourced from the load balancer.
 - *Bastion Security Group*: A security group for the bastion host is created to allow SSH from anywhere.
Note: the outbound traffic for all security groups is allowed.
 - *Private Security Group*: A security group is created for use by instances in the private subnets to allow HTTP (from anywhere), SSH (from the internal network), and ICMP (from the internal network).

**Network Access Control Lists (NACL)**. 

 - *Public NACL*: A NACL associated to the public subnets is created to allow ingress traffic for HTTP (from anywhere), SSH (from anywhere), ephemeral ports (from anywhere) and ICMP (from the internal network). 
 It allows outbound traffic for HTTP ( to anywhere), SSH (to anywhere), ephemeral ports (to anywhere), and ICMP (to the internal network).
 - *Private NACL*: A NACL associated to the private subnets is created to allow ingress traffic for HTTP (from anywhere), SSH (from the internal network), ephemeral ports (from anywhere), and ICMP (from the internal network).
 It also allows outbound traffic for HTTP (to anywhere), SSH (to the internal network), ephemeral ports (to anywhere), and ICMP (to the internal network). [[Ref. Link for ICMP config.]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) 

### Task 3: Instances Configuration (web server and bastion)
Here the configuration required for defining EC2 instances are implemented. Two different instances exist in the `ec2.tf` file.
**Web Servers**
Since the web servers will be provisioned automatically by the auto scaler, a launch configuration (or template) is required. The configuration for creating a launch configuration resource is provided by the `aws_launch_config` variable that has the following default values in the `variables.tf` file.
```
default = {
    name_prefix                 = "web-"
    image_id                    = "ami-0df4b2961410d4cff"
    instance_type               = "t2.micro"
    user_data_file_path         = "user-data.sh"
    associate_public_ip_address = true
  }
   ```
Note: the `user-data.sh` file contains the installation of the Apache server and a custom web page that uses the instance metadata.
Also, the launch configuration resource associates the *Web Server Security Group* with the instance. 

 - [ ] A key pair is created using the variable `key_pair_public` that holds the public key. The user must input the public key when applying the template. This key pair is to allow the operation staff access the web servers through the bastion host. The key pair is named `web`.

**Bastion Host**
An EC2 instance is created for the bastion host with the information received from the variables such as `bastion_ami` (default is an Ubuntu instance, similar to the one used for the web servers), `bastion_instance_type` (default is `t2.micro`), and `key_pair_public`. A key pair is created using the provided public key as `bastion`. 

 - [ ] The key pairs are shared between the web server and bastion, just for simplicity and tests. Not a good practice, though.
The bastion host will be deployed in the first public subnet and be associated with a public IP. 

 - [ ] A multi-AZ deployment of the bastion host will be a better practice for high availability.
 
Lastly, the Bastion Security Group is associated to the instance.

### Task 4: Load Balancing
An Elastic Load Balancer (ELB) is created in the `elb.tf` file to provide a single point of contact to the users and proper distribution of load between instances of the web server. Note that all the ELB configuration is hardcoded in the template and no input variable is set for simplicity.

 - *Application Load Balancer*: The load balancer type is `applicaiton` and is an internet-facing service that also is associated with the *Load Balancer Security Group*.
- *Listener*: The listener receives users' requests on port 80 and forwards them to the web servers defined in the target group.
- *Target Group*: The target group is configured to receive HTTP requests on port 80 and distribute them among the instances using a round robin algorithm. It also enables health checks to ensure only healthy targets receive the requests [[Ref. Link]](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#health_check).

### Task 5: Auto Scaling
To respond to the varying demand, the web server instances need to scale in and out dynamically. Hence, an Auto Scaling Group is created in the `asg.tf` file to implement this logic.

 1. *Auto Scaling Group*: This resource defines the auto scaler behaviour in terms of the capacity. It is created based on the information provided by the `asg` variable  in the `variables.tf` file that defaults to this:
```
default = {
        name = "web"
        max_size = 3
        min_size = 1
        desired_capacity = 2
    }
```
 - This resource is configured to launch instances using the defined launch configuration (previously defined in Task 3). Given this dependency, the auto scaling group resource must wait for the launch configuration resource to complete.
 - This is configured to launch the instances only in the public subnets by its `vpc_zone_identifier` parameter.
 - Since the instances created by the auto scaling group are out of the control of the Terraform provider, [auto-tagging](https://developer.hashicorp.com/terraform/tutorials/aws/aws-default-tags) using the `default_tags` fails to apply to them. Instead a `dynamic` argument is used to handle this as follow.
 ```
 dynamic "tag" {
        for_each = data.aws_default_tags.current.tags
        content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
        }
    }
```
 2. *Auto Scaling Policy*: This resource is created to specify the policy by which the scaling actions occur. For simplicity, the `TargetTrackingScaling` is used as defined by the `asg_policy` variable default value in the `variables.tf` file as follows. Then this auto scaling policy is associated to the auto scaling group.
 3. *Target Tracker*: Given the policy, a the configuraiton for a target tracker is required. Hence, a Target Tracking Configuraiton resource is created that sets two parameters. A predefined metric specification that receives its predefined_metric_type as `ASGAverageCPUUtilization` from the default value of the `asg_policy_target_config_metric` variable. It also sets a `target_value` for tracking using the default value of `80` received from the `asg_policy_target_config_value` variable.

4. *Load Balancer Attachment*: The auto scaler is attached to the load balancer such that the dynamicity of the load and instances are managed by the both services automatically ([Ref. 1](https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg), [2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment)). 



### Miscellaneous
- The `variables.tf` file defines the required variables for the template to create the resources.
- The `data.tf` files is created to produce required data for the template use such as a list of public and private subnets.
- The `output.tf` file is created to print the load balancer DNS when created. I acknowledge that several other information could have been collected.
- The `terraform.tfvars` file is created to provide some of the variables values. It currently only contains the values for the `common_tags` variable that is required for the template.
- Should you need to overwrite the variables, you may have a look at the [Variable Definition Precedence](https://developer.hashicorp.com/terraform/language/values/variables#variable-definition-precedence).

### How to Run the Template!
Simply to the followings.
- download the code 
- configure your AWS CLI 
- run Terraform commands (init, validate, plan, and then apply). 
	- Note: It will prompt for `profile` and `key_pair_public` values that are your preferred AWS CLI profile name and the public SSH key you want to use for both bastion host and web servers.
- When the deployment is successfully completed, run this command to send a request to the application.
`curl $(terraform output -raw load_balancer_DNS):80`
- Clean Up: run `terraform destroy` to destroy all the provisioned resources.

---

### Some questions
**Please describe how you would implement the following requirements:**

- *Question*: How would you provide shell access into the application stack for operations staff who may want to log into an instance?
	- *Answer*: The bastion host is designed to serve this purpose. Operations staff can SSH to the bastion host and from there jump to the web servers or even any resource inside the private subnets. The bastion host could have been deployed to a dedicated public subnet for further network isolation.
	- The bastion host access logs could be stored in a S3 bucket for compliance, as explained [here](https://aws.amazon.com/solutions/implementations/linux-bastion/) and [here](https://aws.amazon.com/blogs/security/how-to-record-ssh-sessions-established-through-a-bastion-host/).
	- Another solution could be the use of IAM and Systems Manager as explained [here](https://segment.com/blog/infrastructure-access/) and [here](https://aws.amazon.com/blogs/mt/replacing-a-bastion-host-with-amazon-ec2-systems-manager/). This means the instances can run an SSM agent and then with particular IAM roles attached to those instances, the staff can access them securely.

- *Question*: Make access and error logs available in a monitoring service such as AWS CloudWatch or Azure Monitor.
	-*Answer*: The Apache web service running on the EC2 instances firstly must properly be configured to log the access and error logs (preferably in a JSON format). 
       - With the CloudWatch agent enabled on the instances, those logs can be pushed to theCloudWatch Logs, so later on using CloudWatch Logs Insights they can be read, as explained [here](https://aws.amazon.com/blogs/mt/simplifying-apache-server-logs-with-amazon-cloudwatch-logs-insights/).
### Acknowledgment
The sources of the majority of the information provided in this project are the [Terraform Language Docs](https://developer.hashicorp.com/terraform/language) and [Terraform AWS Tutorials](https://developer.hashicorp.com/terraform/tutorials/aws). 

### Limitations
- The *load balancer* can be improved to support *HTTPS*.
- The *Nat Gateway* is currently deployed only in one subnet, but *multi-AZ* deployments provide a greater level of resiliency.
- An *dedicated public subnet* can be designed for the operation staff and *bastion host* instead of combining it with the web server location.
- Access to the bastion host could have been restricted to specific IP addresses for security.
- A WAF service could have been used to support DDoS protection for the application.
- *Baking a launch template* for the web server EC2 instances will be a more efficient way than running the bootstrap file.