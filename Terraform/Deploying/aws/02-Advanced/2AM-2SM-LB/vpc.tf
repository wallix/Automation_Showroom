//  Define the VPC.
resource "aws_vpc" "cluster" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(
    { Name = "VPC-${var.project_name}" },
    var.tags
  )
}

// Retrieve availability zones

data "aws_availability_zones" "available" {
  state = "available"
}



//  Create AM subnet for AZ 1.
resource "aws_subnet" "subnet_az_AM" {
  count                   = var.number-of-am <= 1 ? 2 : var.number-of-am
  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 6, count.index + 3)
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = var.tags

}

//  Create SM subnets
resource "aws_subnet" "subnet_az_SM" {
  count                   = var.number-of-sm <= 1 ? 2 : var.number-of-sm
  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 6, count.index)
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = var.tags

}

//  An Internet Gateway for the VPC.
resource "aws_internet_gateway" "cluster_gateway" {
  vpc_id = aws_vpc.cluster.id

  tags = var.tags

}

// Create a default route
resource "aws_route" "default_route" {
  route_table_id         = aws_vpc.cluster.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cluster_gateway.id

}

locals {
  test = <<EOF
  "${cidrsubnet(var.vpc_cidr, 1, 1)}"
  "${cidrsubnet(var.vpc_cidr, 6, 4)}"
  "${var.vpc_cidr}"
  EOF
}