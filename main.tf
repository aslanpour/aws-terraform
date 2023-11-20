

locals {
  name_suffix = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
  common_tags = {
    Project     = var.common_tags["Project"]
    Environment = var.common_tags["Environment"]
    Owner       = var.common_tags["Owner"]
  }

}


/*
#https://developer.hashicorp.com/terraform/tutorials/configuration-language/checks
check "response" {

  # The data source namespace is scoped within the check block.
  data "http" "web_server" {
    url      = "http://${aws_lb.alb.dns_name}"
    insecure = true
  }

  assert {
    condition     = data.http.web_server.status_code == 200
    error_message = "Web server response is ${data.http.web_server.status_code}"
  }
}



*/