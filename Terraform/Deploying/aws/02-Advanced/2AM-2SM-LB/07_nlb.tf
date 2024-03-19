/*

# Currently Network loadbalancer are not compatible with WALLIX Session Manager
resource "aws_lb_target_group" "front_bastion_rdp" {
  name     = "Session-Manager-Group-RDP"
  port     = 3389
  protocol = "TCP"
  vpc_id   = aws_vpc.cluster.id

  health_check {
    enabled             = true
    port                = 3389
    protocol            = "TCP"
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_target_group_attachment" "attach_sm1_rdp" {
  target_id        = aws_instance.bastion_1.id
  target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  port             = 3389

}


resource "aws_lb_target_group_attachment" "attach_sm2_rdp" {
  target_id        = aws_instance.bastion_2.id
  target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  port             = 3389

}

resource "aws_lb_target_group" "front_bastion_ssh" {
  name     = "Session-Manager-Group-SSH"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.cluster.id

  health_check {
    enabled             = true
    port                = 22
    protocol            = "TCP"
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_target_group_attachment" "attach_sm1_ssh" {
  target_id        = aws_instance.bastion_1.id
  target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  port             = 22

}


resource "aws_lb_target_group_attachment" "attach_sm2_ssh" {
  target_id        = aws_instance.bastion_2.id
  target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  port             = 22

}

resource "aws_lb" "front_sm" {
  name                             = "Session-Manager-Front"
  internal                         = true
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.lb.id]
  enable_cross_zone_load_balancing = true
  subnets = [
    aws_subnet.subnet_az1_SM.id,
    aws_subnet.subnet_az2_SM.id
  ]

  enable_deletion_protection = false

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_listener" "front_end_SSH" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner

  }

}

resource "aws_lb_listener" "front_end_RDP" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "3389"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

*/