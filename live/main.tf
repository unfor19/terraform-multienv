module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~>3.14"
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
  tags = local.tags
}

resource "aws_s3_bucket_acl" "app" {
  bucket = aws_s3_bucket.app.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "app" {
  bucket = aws_s3_bucket.app.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.app.id
  acl          = "public-read"
  key          = "index.html"
  content      = "<h1>Hi from ${var.app_name}, and welcome to the ${var.environment} environment</h1>"
  content_type = "text/html"
  tags   = local.tags
}
