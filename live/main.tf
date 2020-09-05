module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~>2.0"
  name               = local.prefix
  cidr               = local.vpc_cidr
  private_subnets    = local.private_subnets
  public_subnets     = local.public_subnets
  enable_nat_gateway = false
  enable_vpn_gateway = false

  azs = local.availability_zones

  tags = local.tags
}
