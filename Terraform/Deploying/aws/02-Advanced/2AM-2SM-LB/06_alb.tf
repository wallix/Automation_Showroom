resource "tls_private_key" "example" {
  algorithm = "RSA"

}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "wallix-example.com"
    organization = "Wallix"
  }

  validity_period_hours = 3600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_target_group" "front_am" {
  name     = "Access-Manager-Group"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.cluster.id

  health_check {
    path                = "/wabam/favicon.ico"
    protocol            = "HTTPS"
    port                = 443
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200" # has to be HTTP 200 or fails
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_target_group_attachment" "attach_am1" {
  target_id        = aws_instance.am_1.id
  target_group_arn = aws_lb_target_group.front_am.arn
  port             = 443

}


resource "aws_lb_target_group_attachment" "attach_am2" {
  target_id        = aws_instance.am_2.id
  target_group_arn = aws_lb_target_group.front_am.arn
  port             = 443

}

resource "aws_lb" "front_am" {
  name               = "access-manager-front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets = [
    aws_subnet.subnet_az1_AM.id,
    aws_subnet.subnet_az2_AM.id
  ]

  enable_deletion_protection = false

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_listener" "HTTP_to_HTTPS_Redirect" {
  load_balancer_arn = aws_lb.front_am.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
   
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_listener" "Frontend_AM" {

  load_balancer_arn = aws_lb.front_am.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_am.arn
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}

resource "aws_lb_listener_rule" "redirect" {
  listener_arn = aws_lb_listener.Frontend_AM.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      path        = "/wabam/default"
    }
  }

  condition {
    path_pattern {
      values = ["/accounts/*", "/configs/*", "/appliance/*", "/wabam/global*"]
    }
  }

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }

}