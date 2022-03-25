/**
* # Client VPN
*
* Terraform module to deploy AWS Client VPN.
*
* ## Usage
*
* ```hcl
* module "client_vpn" {
*   source            = "../modules/client_vpn"
*   region            = "us-east-1"
*   client_cidr_block = "10.22.0.0/22"
*   vpc_id            = "<vpc_id>"
*   subnet_id         = ["<subnet range>", "<subnet range>"]
*   domain            = "aws-vpn.meltano.com"
*   server_cert       = data.aws_acm_certificate.vpn_server.arn
*   client_cert       = data.aws_acm_certificate.vpn_client.arn
*   split_tunnel      = "true"
* }
* ```
*
* A script ([client_vpn_admin.sh](deploy/client_vpn_admin.sh)) accompanies this module to automate the creation of client certificates for new users. For details of VPN onboarding, take a look at the [handbook]().
*
*/

resource "aws_security_group" "client_vpn_access" {
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

resource "aws_cloudwatch_log_group" "client_vpn_cloudwatch_log_group" {
  name              = "client-vpn-endpoint-${var.domain}"
  retention_in_days = "30"

  tags = {
    Name        = var.domain
    Environment = "global"
    Terraform   = "true"
  }
}

resource "aws_ec2_client_vpn_endpoint" "client_vpn_endpoint" {
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
    cloudwatch_log_group = aws_cloudwatch_log_group.client_vpn_cloudwatch_log_group.name
  }

  tags = {
    Name        = var.domain
    Environment = "global"
    Terraform   = "true"
  }
}

resource "aws_ec2_client_vpn_network_association" "client_vpn_network_association" {
  count                  = length(var.subnet_id)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn_endpoint.id
  subnet_id              = element(var.subnet_id, count.index)
}

resource "null_resource" "authorize_client_vpn_ingress" {
  provisioner "local-exec" {
    when    = create
    command = "aws --region ${var.region} ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client_vpn_endpoint.id} --target-network-cidr 0.0.0.0/0 --authorize-all-groups"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client_vpn_endpoint,
    aws_ec2_client_vpn_network_association.client_vpn_network_association
  ]
}

resource "null_resource" "client_vpn_security_group" {
  provisioner "local-exec" {
    when    = create
    command = "aws ec2 apply-security-groups-to-client-vpn-target-network --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client_vpn_endpoint.id} --vpc-id ${aws_security_group.client_vpn_access.vpc_id} --security-group-ids ${aws_security_group.client_vpn_access.id}"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client_vpn_endpoint,
    aws_security_group.client_vpn_access
  ]
}