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

output "alb_dns" {
  value = aws_lb.front_am.dns_name

}
output "elb_dns" {
  value = aws_elb.elb_bastion.dns_name

}

output "wallix_password_wabadmin" {
  value = random_string.password_wabadmin.result

}
output "wallix_password_wabsuper" {
  value = random_string.password_wabsuper.result

}
output "wallix_password_wabupgrade" {
  value = random_string.password_wabupgrade.result

}

output "z_connect" {
  value = "Connect to the debian instance: ssh -Xi ./private_key.pem admin@${aws_instance.debian_admin.public_ip} "

}