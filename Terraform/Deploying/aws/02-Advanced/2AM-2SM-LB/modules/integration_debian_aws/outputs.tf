
output "public_ip_debian_admin" {
  description = "Public IP of the debian instance."
  value       = aws_eip.public_ip_debian.public_ip

}

output "private_ip_debian_admin" {
  description = "Private IP of the debian instance."
  value       = aws_instance.debian_admin.private_ip

}

output "password_rdpuser" {
  description = "Generated password for rdp connexion with rdpuser."
  value       = random_password.password_rdpuser.result
  sensitive   = true
}

output "z_connect" {
  description = "How to connect to instance."
  value       = "Connect to the debian instance: ssh -Xi ./generated_files/private_key.pem admin@${aws_eip.public_ip_debian.public_ip}"

}

output "cloudinit_config" {
  description = "Content of the cloud init. Mostly for debug"
  value       = data.cloudinit_config.integration_debian.rendered
}