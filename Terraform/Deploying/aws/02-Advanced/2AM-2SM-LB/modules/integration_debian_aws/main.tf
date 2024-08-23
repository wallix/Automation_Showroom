// Get latest Debian Linux AMI
data "aws_ami" "debian-linux" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["debian-12*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}

// Generate rdpuser password
resource "random_password" "password_rdpuser" {
  length           = 16
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!-_=+:?"
  special          = true

}
locals {
  encoded_private_key = base64encode(var.private_key)
}

// Generate Debian Cloud Init file from template

data "cloudinit_config" "integration_debian" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "kickstart-script.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/kickstart-script.sh")
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init-conf-DEBIAN.tpl", { password_rdpuser = "${random_password.password_rdpuser.result}", private_key = "${local.encoded_private_key}" })
  }
}


// Security Group
resource "aws_security_group" "debian_admin" {
  name        = "firewall-${var.project_name}-debian-admin"
  description = "Allow traffic for ${var.project_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.allowed_ips, var.sm-instances)
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = concat(var.allowed_ips, var.sm-instances)
  }

  ingress {
    description = "RAWTCPIP_TEST"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.sm-instances
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
// Create a network interface
resource "aws_network_interface" "debian-linux" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.debian_admin.id]

  tags = merge(
    { Name = "integration-debian" },
    var.tags
  )

}

resource "aws_eip" "public_ip_debian" {
  instance = aws_instance.debian_admin.id
}

resource "aws_instance" "debian_admin" {
  ami           = data.aws_ami.debian-linux.id
  instance_type = var.aws_instance_size

  key_name = var.key_pair_name

  user_data = data.cloudinit_config.integration_debian.rendered

  network_interface {
    network_interface_id = aws_network_interface.debian-linux.id
    device_index         = 0
  }

  tags = merge(
    { "Name" = "Integration_Debian-${var.project_name}" },
    var.common_tags
  )

}
