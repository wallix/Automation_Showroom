// Other

output "ssh_private_key" {
  value     = module.ssh_aws.ssh_private_key
  sensitive = true
}

output "alb_fqdn" {
  value = aws_lb.front_am.dns_name
}

output "nlb_fqdn" {
  value = aws_lb.front_sm.dns_name
}

// SM

output "sm_password_wabadmin" {
  value     = module.cloud-init-sm.wallix_password_wabadmin
  sensitive = true
}

output "sm_password_wabsuper" {
  value     = module.cloud-init-sm.wallix_password_wabsuper
  sensitive = true
}

output "sm_password_wabupgrade" {
  value     = module.cloud-init-sm.wallix_password_wabupgrade
  sensitive = true
}

output "sm1_private_ip" {
  value = module.instance_bastion1.instance_private_ip
}

output "sm1_id" {
  value = module.instance_bastion1.instance-id
}

output "sm2_private_ip" {
  value = module.instance_bastion2.instance_private_ip
}
output "sm2_id" {
  value = module.instance_bastion1.instance-id
}


// AM

output "am_password_wabadmin" {
  value     = module.cloud-init-am.wallix_password_wabadmin
  sensitive = true
}

output "am_password_wabsuper" {
  value     = module.cloud-init-am.wallix_password_wabsuper
  sensitive = true
}

output "am_password_wabupgrade" {
  value     = module.cloud-init-am.wallix_password_wabupgrade
  sensitive = true
}

output "am1_private_ip" {
  value = module.instance_access_manager1.instance_private_ip
}

output "am2_private_ip" {
  value = module.instance_access_manager2.instance_private_ip
}

// Debian

output "debian_public_ip" {
  value = module.integration_debian.public_ip_debian_admin
}

output "debian_connect" {
  value = module.integration_debian.z_connect
}

output "debianpassword_rdpuser" {
  value     = module.integration_debian.password_rdpuser
  sensitive = true
}