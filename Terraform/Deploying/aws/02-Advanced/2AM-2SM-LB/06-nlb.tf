resource "aws_lb_target_group" "front_bastion_rdp" {
  name               = "SM-Group-RDP-${var.project_name}"
  port               = 3389
  protocol           = "TCP"
  vpc_id             = aws_vpc.cluster.id
  preserve_client_ip = true

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

  tags = local.common_tags
}

resource "aws_lb_target_group" "front_bastion_ssh" {
  name               = "SM-Group-SSH-${var.project_name}"
  port               = 22
  protocol           = "TCP"
  preserve_client_ip = true
  vpc_id             = aws_vpc.cluster.id

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

  tags = local.common_tags

}

resource "aws_lb_target_group" "front_bastion_https" {
  name               = "SM-Group-HTTPS-${var.project_name}"
  port               = 443
  protocol           = "TCP"
  preserve_client_ip = true
  vpc_id             = aws_vpc.cluster.id

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

  tags = local.common_tags

}

resource "aws_lb" "front_sm" {
  name                             = "sm-front-${var.project_name}"
  internal                         = var.nlb_internal
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.nlb.id]
  enable_cross_zone_load_balancing = true
  subnets                          = aws_subnet.subnet_az_SM.*.id

  enable_deletion_protection = false

  tags = local.common_tags

}

resource "aws_lb_listener" "front_end_HTTPS" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_https.arn
  }

  tags = local.common_tags

}


resource "aws_lb_listener" "front_end_SSH" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  }

  tags = local.common_tags

}

resource "aws_lb_listener" "front_end_RDP" {
  load_balancer_arn = aws_lb.front_sm.arn
  port              = "3389"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  }

  tags = local.common_tags

}


resource "aws_lb_target_group_attachment" "attach_sm_ssh" {
  count            = var.number-of-sm
  target_id        = module.instance_bastion[count.index].instance-id
  target_group_arn = aws_lb_target_group.front_bastion_ssh.arn
  port             = 22

}
resource "aws_lb_target_group_attachment" "attach_sm_https" {
  count            = var.number-of-sm
  target_id        = module.instance_bastion[count.index].instance-id
  target_group_arn = aws_lb_target_group.front_bastion_https.arn
  port             = 443

}

resource "aws_lb_target_group_attachment" "attach_sm_rdp" {
  count            = var.number-of-sm
  target_id        = module.instance_bastion[count.index].instance-id
  target_group_arn = aws_lb_target_group.front_bastion_rdp.arn
  port             = 3389

}
