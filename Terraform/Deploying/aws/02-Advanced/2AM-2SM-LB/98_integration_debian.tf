// Generate Debian Cloud Init file from template
data "template_file" "debian" {
  template = file("cloud-init-conf-DEBIAN.tpl")

}

// Get latest Debian Linux AMI
data "aws_ami" "debian-linux" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["debian-11*"]
  }

}
// Generate rdpuser password
resource "random_string" "password_rdpuser" {
  length           = 16
  special          = true
  override_special = "!-_=+<>:?"

}


// Create a network interface
resource "aws_network_interface" "debian-linux" {
  subnet_id       = aws_subnet.subnet_az1_AM.id
  security_groups = [aws_security_group.debian_admin.id]

  tags = {
    Name          = "primary_network_interface"
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_instance" "debian_admin" {
  ami           = data.aws_ami.debian-linux.id
  instance_type = var.aws_instance_size_debian

  key_name = aws_key_pair.key_pair.key_name

  user_data = data.template_file.debian.rendered


  network_interface {
    network_interface_id = aws_network_interface.debian-linux.id
    device_index         = 0
  }

  tags = {
    Name          = "Integration_Debian-${local.project_name}"
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

// Create a public IP and associate it to the Debian machine
resource "aws_eip" "ip_public_debian_admin" {
  domain            = "vpc"
  network_interface = aws_network_interface.debian-linux.id

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

// Push the generated ssh key on the debian host
resource "null_resource" "provisionning" {
  depends_on = [
    aws_eip.ip_public_debian_admin,
    aws_instance.debian_admin
  ]

  provisioner "file" {
    source      = "private_key.pem"
    destination = "/home/admin/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "admin"
      private_key = tls_private_key.key_pair.private_key_pem
      host        = aws_instance.debian_admin.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/admin/.ssh/id_rsa",
      "sudo apt update",
      "sudo apt full-upgrade -y",
      "sudo useradd -p \"$(openssl passwd -6 ${random_string.password_rdpuser.id})\" -m rdpuser ",
      "sudo adduser xrdp ssl-cert",
      "sudo systemctl restart xrdp",
      "sudo systemctl enable xrdp ",
      "sudo groupadd tsusers",
      "sudo adduser rdpuser tsusers"
    ]

    connection {
      type        = "ssh"
      user        = "admin"
      private_key = tls_private_key.key_pair.private_key_pem
      host        = aws_instance.debian_admin.public_ip
    }
  }

}

// Security Group
resource "aws_security_group" "debian_admin" {
  name        = "firewall-${local.project_name}-debian-admin"
  description = "Allow traffic for ${local.project_name}"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(var.allowed_ips, local.sm_instances)
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = concat(var.allowed_ips, local.sm_instances)
  }

  ingress {
    description = "RAWTCPIP_TEST"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = local.sm_instances
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name          = "Integration_Debian-${local.project_name}"
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}



output "public_ip_debian_admin" {
  value = aws_instance.debian_admin.public_ip

}

output "private_ip_debian_admin" {
  value = aws_instance.debian_admin.private_ip

}

output "debian_rdpuser_password" {
  value = random_string.password_rdpuser.id

}

output "z_connect" {
  value = "Connect to the debian instance: ssh -Xi ./private_key.pem admin@${aws_instance.debian_admin.public_ip}"

}
