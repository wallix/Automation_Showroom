// Other
output "ssh_private_key" {
  value     = module.ssh_aws.ssh_private_key
  sensitive = true
}

output "am_url_alb" {
  value = aws_lb.front_am.dns_name
}

output "sm_fqdn_nlb" {
  value = aws_lb.front_sm.dns_name
}

// SM

output "sm-ami" {
  value = one(toset(module.instance_bastion[*].ami-info))
}

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

output "sm_private_ip" {
  value = module.instance_bastion.*.instance_private_ip
}
output "sm_ids" {
  value = module.instance_bastion.*.instance-id
}


// AM

output "am-ami" {
  value = one(toset(module.instance_access_manager[*].ami-info))
}

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

output "am_private_ip" {
  value = module.instance_access_manager.*.instance_private_ip
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





output "availability_zones" {
  value = data.aws_availability_zones.available.names[0]
}