resource "aws_network_interface" "bastion_1" {
  subnet_id   = aws_subnet.subnet_az1_SM.id
  description = "Session_Manager_01-${local.project_name}"

  tags = {
    Name          = "primary_network_interface"
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_network_interface_sg_attachment" "bastion_1" {
  security_group_id    = aws_security_group.bastion_sg.id
  network_interface_id = aws_network_interface.bastion_1.id

}

resource "aws_instance" "bastion_1" {
  ami           = data.aws_ami.bastion_ami.id
  instance_type = var.aws_instance_size

  key_name  = aws_key_pair.key_pair.key_name
  user_data = data.template_file.wallix.rendered
  network_interface {
    network_interface_id = aws_network_interface.bastion_1.id
    device_index         = 0
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "Session_Manager_01-${local.project_name}"
  }
}

resource "aws_network_interface" "bastion_2" {
  subnet_id   = aws_subnet.subnet_az2_SM.id
  description = "Session_Manager_02-${local.project_name}"

  tags = {
    Name          = "primary_network_interface"
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_network_interface_sg_attachment" "bastion_2" {
  security_group_id    = aws_security_group.bastion_sg.id
  network_interface_id = aws_network_interface.bastion_2.id

}

resource "aws_instance" "bastion_2" {
  ami           = data.aws_ami.bastion_ami.id
  instance_type = var.aws_instance_size
  user_data     = data.template_file.wallix.rendered

  key_name = aws_key_pair.key_pair.key_name

  network_interface {
    network_interface_id = aws_network_interface.bastion_2.id
    device_index         = 0
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "Session_Manager_02-${local.project_name}"
  }

}