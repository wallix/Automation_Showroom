// Default Security Group for VPC
// Restrict all
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.cluster.id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "Default_SG-${local.project_name}"
  }

}
// generate list of network for SG rules
locals {
  all_az1_az2_subnets = [
    var.subnet_az1_AM,
    var.subnet_az2_AM,
    var.subnet_az1_SM,
    var.subnet_az2_SM,
  ]

  am_instances = [
    "${aws_instance.am_1.private_ip}/32",
    "${aws_instance.am_2.private_ip}/32"
  ]

  sm_instances = [
    "${aws_instance.bastion_1.private_ip}/32",
    "${aws_instance.bastion_2.private_ip}/32"
  ]

}

// Access Manager
resource "aws_security_group" "accessmanager_sg" {

  name        = "firewall-am-${local.project_name}"
  description = "Allow traffic for ${local.project_name}"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "SSH Admin"
    from_port   = 2242
    to_port     = 2242
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = local.am_instances
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "AM_SG-${local.project_name}"
  }

}

// Bastion
resource "aws_security_group" "bastion_sg" {
  description = "Allow traffic for ${local.project_name}"
  name        = "firewall-bastion-${local.project_name}"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "Proxy_SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "Proxy_RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "SSH Admin"
    from_port   = 2242
    to_port     = 2242
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
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
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "SM_SG-${local.project_name}"
  }

}

// Load Balancer
resource "aws_security_group" "lb" {
  description = "Allow traffic for ${local.project_name} on Loadbalancer"
  name        = "firewall-${local.project_name}-lb"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
    Name          = "LB_SG-${local.project_name}"
  }

}