variable "app_name" {
  type    = string
  default = "tfmonorepo"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "development, staging, production"
}

variable "cidr_ab" {
  type = map
  default = {
    development = "10.1"
    staging     = "10.2"
    production  = "10.3"
  }
}

locals {
  vpc_cidr = "${lookup(var.cidr_ab, var.environment)}.0.0/16"
  public_subnets = [
    "${lookup(var.cidr_ab, var.environment)}.1.0/24",
    "${lookup(var.cidr_ab, var.environment)}.2.0/24",
  ]
  private_subnets = [
    "${lookup(var.cidr_ab, var.environment)}.10.0/24",
    "${lookup(var.cidr_ab, var.environment)}.20.0/24",
  ]
}
