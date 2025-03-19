resource "aws_efs_file_system" "efs-example" {
  creation_token   = "efs-example"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"
  tags             = local.common_tags
}

resource "aws_security_group" "efs_sg" {
  vpc_id = aws_vpc.cluster.id

  ingress {
    description = "Access to EFS from SM"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = local.sm_instances
  }

}

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = var.number-of-sm
  file_system_id  = aws_efs_file_system.efs-example.id
  subnet_id       = aws_subnet.subnet_az_SM[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}