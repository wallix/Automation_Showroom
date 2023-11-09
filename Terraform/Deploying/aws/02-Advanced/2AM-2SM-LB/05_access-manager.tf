resource "aws_network_interface" "am_1" {
  subnet_id = aws_subnet.subnet_az1_AM.id

  tags = {
    Name = "primary_network_interface"
  }

}

resource "aws_network_interface_sg_attachment" "am1" {
  security_group_id    = aws_security_group.accessmanager_sg.id
  network_interface_id = aws_network_interface.am_1.id
}

resource "aws_instance" "am_1" {
  ami           = data.aws_ami.am_ami.id
  instance_type = var.aws_instance_size

  key_name = aws_key_pair.key_pair.key_name

  network_interface {
    network_interface_id = aws_network_interface.am_1.id
    device_index         = 0
  }

  tags = {
    Project = local.project_name
  }
}

resource "aws_network_interface" "am_2" {
  subnet_id = aws_subnet.subnet_az2_AM.id

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface_sg_attachment" "am2" {
  security_group_id    = aws_security_group.accessmanager_sg.id
  network_interface_id = aws_network_interface.am_2.id
}


resource "aws_instance" "am_2" {
  ami           = data.aws_ami.am_ami.id
  instance_type = var.aws_instance_size

  key_name = aws_key_pair.key_pair.key_name

  network_interface {
    network_interface_id = aws_network_interface.am_2.id
    device_index         = 0
  }

  tags = {
    Project = local.project_name
  }
}
