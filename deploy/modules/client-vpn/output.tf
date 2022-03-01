output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
}

output "client_vpn_security_group" {
  value = aws_security_group.client-vpn-access.id
}