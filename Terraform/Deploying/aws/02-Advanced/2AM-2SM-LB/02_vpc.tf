//  Define the VPC.
resource "aws_vpc" "cluster" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Project = local.project_name
  }

}

//  Create AM subnet for AZ 1.
resource "aws_subnet" "subnet_az1_AM" {

  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.subnet_az1_AM
  map_public_ip_on_launch = false

  availability_zone = var.primary_az

  tags = {
    Project = local.project_name
  }

}

//  Create AM subnet for AZ 2
resource "aws_subnet" "subnet_az2_AM" {

  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.subnet_az2_AM
  map_public_ip_on_launch = false

  availability_zone = var.secondary_az

  tags = {
    Project = local.project_name
  }

}

//  Create SM subnet for AZ 1
resource "aws_subnet" "subnet_az1_SM" {

  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.subnet_az1_SM
  map_public_ip_on_launch = false

  availability_zone = var.primary_az

  tags = {
    Project = local.project_name
  }

}

//  Create SM subnet for AZ 2
resource "aws_subnet" "subnet_az2_SM" {

  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.subnet_az2_SM
  map_public_ip_on_launch = true

  availability_zone = var.secondary_az

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}



//  An Internet Gateway for the VPC.
resource "aws_internet_gateway" "cluster_gateway" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

// Create a default route
resource "aws_route" "default_route" {
  route_table_id         = aws_vpc.cluster.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cluster_gateway.id

}