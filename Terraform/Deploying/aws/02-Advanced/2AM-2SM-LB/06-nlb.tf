resource "aws_lb_target_group" "front_bastion_rdp" {
  name     = "SM-Group-RDP-${var.project_name}"
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

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "attach_sm1_rdp" {
  target_id        = module.instance_bastion1.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  port             = 3389

}


resource "aws_lb_target_group_attachment" "attach_sm2_rdp" {
  target_id        = module.instance_bastion2.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  port             = 3389

}

resource "aws_lb_target_group" "front_bastion_ssh" {
  name     = "SM-Group-SSH-${var.project_name}"
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

  tags = var.tags

}

resource "aws_lb_target_group_attachment" "attach_sm1_ssh" {
  target_id        = module.instance_bastion1.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  port             = 22

}


resource "aws_lb_target_group_attachment" "attach_sm2_ssh" {
  target_id        = module.instance_bastion2.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  port             = 22

}

resource "aws_lb_target_group" "front_bastion_https" {
  name     = "SM-Group-HTTPS-${var.project_name}"
  port     = 443
  protocol = "TCP"
  vpc_id   = aws_vpc.cluster.id

  health_check {
    enabled             = true
    port                = 443
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

  tags = var.tags

}

resource "aws_lb_target_group_attachment" "attach_sm1_https" {
  target_id        = module.instance_bastion1.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_https.arn
  port             = 443

}


resource "aws_lb_target_group_attachment" "attach_sm2_https" {
  target_id        = module.instance_bastion2.instance-id
  target_group_arn = aws_lb_target_group.front_bastion_https.arn
  port             = 443

}

resource "aws_lb" "front_sm" {
  name                             = "session-manager-front-${var.project_name}"
  internal                         = true
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.nlb.id]
  enable_cross_zone_load_balancing = true
  subnets = [
    aws_subnet.subnet_az1_SM.id,
    aws_subnet.subnet_az2_SM.id
  ]

  enable_deletion_protection = false

  tags = var.tags

}

resource "aws_lb_listener" "front_end_HTTPS" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_https.arn
  }

  tags = var.tags

}


resource "aws_lb_listener" "front_end_SSH" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  }

  tags = var.tags

}

resource "aws_lb_listener" "front_end_RDP" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "3389"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  }

  tags = var.tags

}
