// Default Security Group for VPC
// Only traffic between its members: AM/SM interfaces carry it next to their own SG.
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
    local.common_tags
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
    description     = "HTTPS_from_ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
    cidr_blocks = length(local.am_instances) >= 1 ? local.am_instances : []
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.all_az1_az2_subnets
  }
  egress {
    description      = "Allow egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { Name = "SG_AM" },
    local.common_tags
  )

}

resource "aws_network_interface_sg_attachment" "wallix-am" {
  count                = var.number_of_am
  security_group_id    = aws_security_group.accessmanager_sg.id
  network_interface_id = module.instance_access_manager[count.index].instance_network_interface_id
}
// Bastion
resource "aws_security_group" "bastion_sg" {
  name        = "firewall-sm-${local.project_name}"
  description = "Allow traffic for ${local.project_name}"
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

  // The NLB preserves client IPs: referencing its SG lets those clients through.
  dynamic "ingress" {
    for_each = { Proxy_SSH_from_NLB = 22, Proxy_RDP_from_NLB = 3389, HTTPS_from_NLB = 443 }
    content {
      description     = ingress.key
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.nlb.id]
    }
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
    description      = "Allow egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { Name = "SG_SM" },
    local.common_tags
  )

}
resource "aws_network_interface_sg_attachment" "wallix-sm" {
  count                = var.number_of_sm
  security_group_id    = aws_security_group.bastion_sg.id
  network_interface_id = module.instance_bastion[count.index].instance_network_interface_id
}

// Load Balancers: reachable from allowed_ips and from inside the VPC (see locals).

resource "aws_security_group" "alb" {
  name        = "firewall-alb-${local.project_name}"
  description = "Allow traffic for ${local.project_name} on Loadbalancer"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.alb_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.alb_allowed_cidrs
  }

  egress {
    description      = "Allow egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { Name = "SG_ALB" },
    local.common_tags
  )

}

resource "aws_security_group" "nlb" {
  name        = "firewall-nlb-${local.project_name}"
  description = "Allow traffic for ${local.project_name} on Network Loadbalancer"
  vpc_id      = aws_vpc.cluster.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.nlb_allowed_cidrs
  }
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = local.nlb_allowed_cidrs
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.nlb_allowed_cidrs
  }
  egress {
    description      = "Allow egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { Name = "SG_NLB" },
    local.common_tags
  )

}
// Note : with an internet-facing NLB, the Bastion proxies are reachable from allowed_ips through the NLB SG.