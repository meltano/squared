<!-- BEGIN_TF_DOCS -->
# Client VPN

Terraform module to deploy AWS Client VPN.

## Usage

```hcl
module "client_vpn" {
  source            = "../modules/client_vpn"
  region            = "us-east-1"
  client_cidr_block = "10.22.0.0/22"
  vpc_id            = "<vpc_id>"
  subnet_id         = ["<subnet range>", "<subnet range>"]
  domain            = "aws-vpn.meltano.com"
  server_cert       = data.aws_acm_certificate.vpn_server.arn
  client_cert       = data.aws_acm_certificate.vpn_client.arn
  split_tunnel      = "true"
}
```

A script ([client\_vpn\_admin.sh](deploy/client\_vpn\_admin.sh)) accompanies this module to automate the creation of client certificates for new users. For details of VPN onboarding, take a look at the [handbook]().

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.client_vpn_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_client_vpn_endpoint.client_vpn_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.client_vpn_network_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_security_group.client_vpn_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [null_resource.authorize_client_vpn_ingress](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.client_vpn_security_group](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_cert"></a> [client\_cert](#input\_client\_cert) | Client/Root certificate | `any` | n/a | yes |
| <a name="input_client_cidr_block"></a> [client\_cidr\_block](#input\_client\_cidr\_block) | The IPv4 address range, in CIDR notation being /22 or greater, from which to assign client IP addresses | `string` | `"10.22.0.0/22"` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | n/a | `list(any)` | <pre>[<br>  "8.8.8.8",<br>  "1.1.1.1"<br>]</pre> | no |
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | `"aws-vpn.meltano.com"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-1"` | no |
| <a name="input_server_cert"></a> [server\_cert](#input\_server\_cert) | Server certificate | `any` | n/a | yes |
| <a name="input_split_tunnel"></a> [split\_tunnel](#input\_split\_tunnel) | n/a | `string` | `"false"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet to associate with the Client VPN endpoint. | `list(any)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to associate with the Client VPN endpoint. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_vpn_endpoint_id"></a> [client\_vpn\_endpoint\_id](#output\_client\_vpn\_endpoint\_id) | n/a |
| <a name="output_client_vpn_security_group"></a> [client\_vpn\_security\_group](#output\_client\_vpn\_security\_group) | n/a |
<!-- END_TF_DOCS -->