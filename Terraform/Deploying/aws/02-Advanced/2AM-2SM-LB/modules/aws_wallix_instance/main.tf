terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.85.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.5.2"
    }
  }
}
resource "aws_network_interface" "wallix" {
  subnet_id   = var.subnet_id
  description = "${var.instance_name}-${var.project_name}"

  tags = merge(
    { Name = "primary_network_interface_${var.instance_name}-${var.project_name}" },
    var.common_tags
  )

}

locals {
  ami-owner    = var.ami_from_aws_marketplace ? "aws-marketplace" : "519101999238" // 519101999238 -> WALLIX
  product_name = replace(var.product_name, "-", ".*")
}

data "aws_ami" "wallix-ami" {
  most_recent = true
  owners      = ["${local.ami-owner}"]
  name_regex  = "^${local.product_name}-${var.product_version}.*aws"

}

resource "aws_instance" "wallix" {
  ami           = var.ami_override != "" ? var.ami_override : data.aws_ami.wallix-ami.id
  instance_type = var.aws_instance_size
  user_data     = var.user_data
  key_name      = var.key_pair_name
  root_block_device {
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = var.disk_size
    volume_type           = var.disk_type
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.wallix.id
    device_index         = 0
  }

  tags = merge(
    { Name = "${var.instance_name}" },
    var.common_tags
  )
}
