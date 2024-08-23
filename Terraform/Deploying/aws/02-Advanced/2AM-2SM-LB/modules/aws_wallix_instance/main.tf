resource "aws_network_interface" "wallix" {
  subnet_id   = var.subnet_id
  description = "${var.instance_name}-${var.project_name}"

  tags = merge(
    { Name = "primary_network_interface_${var.instance_name}-${var.project_name}" },
    var.common_tags
  )

}

resource "aws_network_interface_sg_attachment" "wallix" {
  security_group_id    = var.security_group_id
  network_interface_id = aws_network_interface.wallix.id
}

resource "aws_instance" "wallix" {
  ami           = var.wallix_ami
  instance_type = var.aws_instance_size
  user_data     = var.user_data
  key_name      = var.key_pair_name
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
    { Name = "${var.instance_name}-${var.project_name}" },
    var.common_tags
  )
}