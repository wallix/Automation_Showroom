resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  dns_names = ["${var.project_name}.lab"]

  subject {
    common_name  = "${var.project_name}.lab"
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
  name     = "AM-Group-${var.project_name}"
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
    matcher             = "200" // has to be code HTTP 200 or considered unhealthy
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }

  tags = local.common_tags

}

resource "aws_lb_target_group_attachment" "attach_am" {
  count            = var.number-of-am
  target_id        = module.instance_access_manager[count.index].instance-id
  target_group_arn = aws_lb_target_group.front_am.arn
  port             = 443

}

resource "aws_lb" "front_am" {
  name               = "am-front-${var.project_name}"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.subnet_az_AM.*.id

  enable_deletion_protection = false
  drop_invalid_header_fields = true
  tags = merge(
    { Name = "ALB-AccessManager-${var.project_name}" },
    local.common_tags
  )

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

  tags = local.common_tags

}

resource "aws_lb_listener" "Frontend_AM" {

  load_balancer_arn = aws_lb.front_am.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type = "forward"
    forward {
      stickiness {
        duration = 3600
        enabled  = true
      }
      target_group {
        arn = aws_lb_target_group.front_am.arn
      }
    }
  }

  tags = local.common_tags

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
      values = ["/accounts/*", "/configs/*", "/appliance/*", "/wabam/global*", "/"]
    }
  }

  tags = local.common_tags

}
