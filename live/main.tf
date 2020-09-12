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

resource "aws_s3_bucket" "app" {
  acl = "public-read"

  website {
    index_document = "index.html"
  }

  tags = local.tags
}

resource "aws_s3_bucket_object" "app" {
  bucket       = aws_s3_bucket.app.id
  key          = "index.html"
  acl          = "public-read"
  content      = "<h1>Welcome to the ${var.environment} environment</h1>"
  content_type = "text/html"

  tags = local.tags
}
