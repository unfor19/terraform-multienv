### Dynamic Values ------------------------------
### ---------------------------------------------
variable "cidr_ab" {
  type = map
  default = {
    dev = "10.1"
    stg = "10.2"
    prd = "10.3"
  }
}
### ---------------------------------------------


### Locals Values -------------------------------
### ---------------------------------------------
locals {
  prefix   = "${var.app_name}-${var.environment}"
  vpc_cidr = "${lookup(var.cidr_ab, var.environment)}.0.0/16"
  public_subnets = [
    "${lookup(var.cidr_ab, var.environment)}.1.0/24",
    "${lookup(var.cidr_ab, var.environment)}.2.0/24",
  ]
  private_subnets = [
    "${lookup(var.cidr_ab, var.environment)}.10.0/24",
    "${lookup(var.cidr_ab, var.environment)}.20.0/24",
  ]
  availability_zones = ["${var.region}a", "${var.region}b"]

  tags = {
    "Environment" : var.environment,
    "Terraform" : "true"
  }
}
### ---------------------------------------------


### Static Values DON'T TOUCH -------------------
### ---------------------------------------------
variable "app_name" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type        = string
  description = "dev, stg, prd"
}
### ---------------------------------------------
