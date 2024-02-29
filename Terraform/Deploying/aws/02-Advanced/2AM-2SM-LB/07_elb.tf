resource "aws_elb" "elb_bastion" {
  name               = "session-manager-elb"
  #availability_zones = [var.primary_az, var.secondary_az]
  subnets = [ aws_subnet.subnet_az1_SM.id, aws_subnet.subnet_az2_SM.id]
  listener {
    instance_port     = 3389
    instance_protocol = "TCP"
    lb_port           = 3389
    lb_protocol       = "TCP"
  }

  listener {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 30
  }

  instances                   = [aws_instance.bastion_1.id, aws_instance.bastion_2.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Project_Name  = local.project_name
    Project_Owner = var.project_owner
  }
}