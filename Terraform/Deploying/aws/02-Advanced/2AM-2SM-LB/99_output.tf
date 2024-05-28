/*
output "aws_instance_ip" {
  value = aws_instance.product_instance.public_ip
}
*/

output "project_name" {
  value = local.project_name

}

output "aws_vpc" {
  value = aws_vpc.cluster.id

}

output "bastion1_instance_id" {
  value = aws_instance.bastion_1.id
}

output "bastion2_instance_id" {
  value = aws_instance.bastion_2.id
}

output "private_ip_am_1" {
  value = aws_instance.am_1.private_ip
}

output "private_ip_am_2" {
  value = aws_instance.am_2.private_ip

}

output "private_ip_bastion_1" {
  value = aws_instance.bastion_1.private_ip

}

output "private_ip_bastion_2" {
  value = aws_instance.bastion_2.private_ip

}

output "alb_dns" {
  value = aws_lb.front_am.dns_name

}

output "nlb_dns" {
  value = aws_lb.front_sm.dns_name

}

/*
output "elb_dns" {
  value = aws_elb.elb_bastion.dns_name

}
*/
output "wallix_password_wabadmin" {
  value = random_string.password_wabadmin.result

}
output "wallix_password_wabsuper" {
  value = random_string.password_wabsuper.result

}
output "wallix_password_wabupgrade" {
  value = random_string.password_wabupgrade.result

}
