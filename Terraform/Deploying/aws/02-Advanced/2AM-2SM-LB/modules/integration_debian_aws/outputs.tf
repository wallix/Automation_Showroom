
output "public_ip_debian_admin" {
  value = aws_eip.public_ip_debian.public_ip

}

output "private_ip_debian_admin" {
  value = aws_instance.debian_admin.private_ip

}

output "password_rdpuser" {
  value     = random_password.password_rdpuser.result
  sensitive = true
}

output "z_connect" {
  value = "Connect to the debian instance: ssh -Xi ./private_key.pem admin@${aws_eip.public_ip_debian.public_ip}"

}

output "cloudinit_config" {
  value = data.cloudinit_config.integration_debian.rendered
}