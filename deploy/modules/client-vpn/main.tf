################################
###  Security Group
################################

resource "aws_security_group" "client-vpn-access" {
  name   = "terraform-shared-client-vpn-access"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################
###  Cloudwatch Log Group
################################

resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name              = "client-vpn-endpoint-${var.domain}"
  retention_in_days = "30"

  tags = {
    Name        = var.domain
    Environment = "global"
    Terraform   = "true"
  }
}

################################
###  Client VPN Endpoint
################################

resource "aws_ec2_client_vpn_endpoint" "client-vpn-endpoint" {
  description            = "terraform-client-vpn-endpoint"
  server_certificate_arn = var.server_cert
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = var.split_tunnel
  dns_servers            = var.dns_servers

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_cert
  }

  connection_log_options {
    enabled              = true
    cloudwatch_log_group = aws_cloudwatch_log_group.cloudwatch-log-group.name
  }

  tags = {
    Name        = var.domain
    Environment = "global"
    Terraform   = "true"
  }
}

resource "aws_ec2_client_vpn_network_association" "client-vpn-network-association" {
  count                  = length(var.subnet_id)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
  subnet_id              = element(var.subnet_id, count.index)
}


################################
###  Null Resource
################################

resource "null_resource" "authorize-client-vpn-ingress" {
  provisioner "local-exec" {
    when    = create
    command = "aws --region ${var.region} ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id} --target-network-cidr 0.0.0.0/0 --authorize-all-groups"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client-vpn-endpoint,
    aws_ec2_client_vpn_network_association.client-vpn-network-association
  ]
}

resource "null_resource" "client-vpn-security-group" {
  provisioner "local-exec" {
    when    = create
    command = "aws ec2 apply-security-groups-to-client-vpn-target-network --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id} --vpc-id ${aws_security_group.client-vpn-access.vpc_id} --security-group-ids ${aws_security_group.client-vpn-access.id}"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client-vpn-endpoint,
    aws_security_group.client-vpn-access
  ]
}