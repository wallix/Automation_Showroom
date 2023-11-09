/*
output "aws_instance_ip" {
  value = aws_instance.product_instance.public_ip
}
*/

output "aws_vpc" {
  value = aws_vpc.cluster.id

}

output "public_ip_debian_admin" {
  value = aws_instance.debian_admin.public_ip

}
output "private_ip_debian_admin" {
  value = aws_instance.debian_admin.private_ip
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

output "lb_dns" {
  value = aws_lb.front_am.dns_name
}