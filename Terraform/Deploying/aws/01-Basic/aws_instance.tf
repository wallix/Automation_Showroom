terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

}

locals {
  image_name    = "${var.product_name}-${var.product_version}-aws"
  instance_name = "instance-${var.product_name}-${var.product_version}"
}
data "aws_ami" "ami" {
  most_recent = true
  filter {
    name   = "name"
    values = [local.image_name]
  }
  owners = ["519101999238"] # WALLIX
}

resource "aws_security_group" "accessmanager_sg" {
  name        = "firewall-${var.product_name}-lab"
  description = "Allow traffic for ${var.product_name}"
  vpc_id      = var.aws_vpc_id
  count       = var.product_name == "access-manager" ? 1 : 0

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    description = "SSH Admin"
    from_port   = 2242
    to_port     = 2242
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "firewall-${var.product_name}-lab"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "firewall-${var.product_name}-lab"
  description = "Allow traffic for ${var.product_name}"
  vpc_id      = var.aws_vpc_id
  count       = var.product_name == "bastion" ? 1 : 0

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }

  ingress {
    description = "SSH Admin"
    from_port   = 2242
    to_port     = 2242
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ip
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "firewall-${var.product_name}-lab"
  }
}

resource "aws_instance" "product_instance" {
  ami           = data.aws_ami.ami.id
  instance_type = var.aws_instance_size

  vpc_security_group_ids = [try(aws_security_group.bastion_sg[0].id, aws_security_group.accessmanager_sg[0].id)]
  key_name               = var.aws_key_name
  tags = {
    Name = local.instance_name
  }
}
