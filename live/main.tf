provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~>2.0"
  name               = "${var.app_name}-vpc-${var.environment}"
  cidr               = local.vpc_cidr
  private_subnets    = local.private_subnets
  public_subnets     = local.public_subnets
  enable_nat_gateway = false
  enable_vpn_gateway = false

  azs = ["${var.region}a", "${var.region}b"]
}
