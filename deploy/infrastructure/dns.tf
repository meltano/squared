

resource "aws_route53_zone" "private" {
  name = "internal-data.meltano.com"

  vpc {
    vpc_id = module.infrastructure.vpc.vpc_id
  }
}