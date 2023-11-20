# To avoid an error message when print sensitive variables, like this error
# "Error: Output refers to sensitive values"
# Add "sensitive = true" to the output items.

#You can use Terraform expressions.
# https://developer.hashicorp.com/terraform/tutorials/configuration-language/expressions

#You can query the outputs by " terraform output <-json|raw> <name>"

output "load_balancer_DNS" {
  value = aws_lb.alb.dns_name
}

#output ELB endpoint
#curl $(terraform output -raw load_balancer_DNS):80