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
  tags = merge(
    { Name = "Default_SG" },
    var.tags
  )

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
    description = "HTTPS_public"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = merge(
    { Name = "SG_AM" },
    var.tags
  )

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
    to_port     = 3307
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

  tags = merge(
    { Name = "SG_SM" },
    var.tags
  )

}

// Load Balancer
resource "aws_security_group" "alb" {
  description = "Allow traffic for ${local.project_name} on Loadbalancer"
  name        = "firewall-${local.project_name}-alb"
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { Name = "SG_ALB" },
    var.tags
  )

}

resource "aws_security_group" "nlb" {
  description = "Allow traffic for ${local.project_name} on Network Loadbalancer"
  name        = "firewall-${local.project_name}-nlb"
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

  tags = merge(
    { Name = "SG_ALB" },
    var.tags
  )

}