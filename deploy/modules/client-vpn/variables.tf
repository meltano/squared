variable "region" {
  default = "us-east-1"
}

variable "client_cidr_block" {
  description = "The IPv4 address range, in CIDR notation being /22 or greater, from which to assign client IP addresses"
  default     = "10.22.0.0/22"
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the Client VPN endpoint."
}

variable "subnet_id" {
  type        = list
  description = "The ID of the subnet to associate with the Client VPN endpoint."
}

variable "domain" {
  default = "aws-vpn.meltano.com"
}

variable "server_cert" {
  description = "Server certificate"
}

variable "client_cert" {
  description = "Client/Root certificate"
}

variable "split_tunnel" {
  default = "false"
}

variable "dns_servers" {
  type = list
  default = [
    "8.8.8.8",
    "1.1.1.1"
  ]
}