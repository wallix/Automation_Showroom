// SM

output "sm-ami" {
  description = "Description of the AMI used for Session Manager."
  value       = (var.number-of-sm != 0 ? (toset(module.instance_bastion[*].ami-info)) : null)
}

output "sm_password_wabadmin" {
  description = "Wabadmin password."
  value       = module.cloud-init-sm.wallix_password_wabadmin
  sensitive   = true
}

output "sm_password_wabsuper" {
  description = "Wabsuper password."
  value       = module.cloud-init-sm.wallix_password_wabsuper
  sensitive   = true
}

output "sm_password_wabupgrade" {
  description = "Wabupgrade password."
  value       = module.cloud-init-sm.wallix_password_wabupgrade
  sensitive   = true
}

output "sm_password_webui" {
  description = "WebUI password."
  value       = module.cloud-init-sm.wallix_password_webui
  sensitive   = true
}

output "sm_password_crypto" {
  description = "WebUI password."
  value       = module.cloud-init-sm.wallix_crypto
  sensitive   = true
}

output "sm_private_ip" {
  description = "List of the private ip used for Session Manager."
  value       = (var.number-of-sm != 0 ? module.instance_bastion.*.instance_private_ip : null)
}
output "sm_ids" {
  description = "List of sm ids. Useful to find the default admin password (admin-<instance-id)"
  value       = (var.number-of-sm != 0 ? module.instance_bastion.*.instance-id : null)
}


// AM

output "am-ami" {
  description = "Description of the AMI used for Access Manager."
  value       = (var.number-of-am != 0 ? one(toset(module.instance_access_manager[*].ami-info)) : null)
}

output "am_password_wabadmin" {
  description = "Wabadmin password."
  value       = module.cloud-init-am.wallix_password_wabadmin
  sensitive   = true
}

output "am_password_wabsuper" {
  description = "Wabsuper password."
  value       = module.cloud-init-am.wallix_password_wabsuper
  sensitive   = true
}

output "am_password_wabupgrade" {
  description = "Wabupgrade password."
  value       = module.cloud-init-am.wallix_password_wabupgrade
  sensitive   = true
}

output "am_private_ip" {
  description = "List of the private ip used for Access Manager."
  value       = (var.number-of-am != 0 ? module.instance_access_manager.*.instance_private_ip : null)
}

// Debian

output "debian_public_ip" {
  description = "Public IP of the Debian instance."
  value       = (var.deploy-integration-debian ? module.integration_debian.*.public_ip_debian_admin : null)
}

output "debian_connect" {
  description = "How to connect to the Debian instance."
  value       = (var.deploy-integration-debian ? module.integration_debian.*.z_connect : null)
}

output "debianpassword_rdpuser" {
  description = "Generated password for rdp connexion with rdpuser."
  value       = (var.deploy-integration-debian ? module.integration_debian.*.password_rdpuser : null)
  sensitive   = true
}

// Other
output "ssh_private_key" {
  description = "The SSH Private key in openssh format."
  value       = module.ssh_aws.ssh_private_key
  sensitive   = true
}

output "am_url_alb" {
  description = "Url to connect to the AM cluster from Application Load Balancer."
  value       = "https://${aws_lb.front_am.dns_name}"

}

output "sm_fqdn_nlb" {
  description = "FQDN of the Network Load Balancer."
  value       = aws_lb.front_sm.dns_name

}

output "availability_zones" {
  description = "Availability zones of the select region."
  value       = data.aws_availability_zones.available.names
}

output "your-public_ip" {
  description = "Your egress public IP."
  value       = chomp(data.http.myip.response_body)
}

output "warning_allowed_ips_too_wild" {
  description = "IP Warnings."
  value       = contains(var.allowed_ips, "0.0.0.0/0") ? "!!!Warning!!!\nAre you sure you want var.allowed_ips to contain the wild of Internet ?\n Prefer to add a list of legitimate networks and/or your <public-IP/32> !" : null

}

output "warning_nlb_internal_false" {
  description = "NLB Warnings."
  value       = var.nlb_internal == false ? "!!!Warning!!!\nYou did nlb_internal set as false.\nIt is fun to open NLB in the wild. But this is totally risky.\n NLB works only with 0.0.0.0/0 as ingress. Keep it internal!" : null

}


output "cloud_init_sm" {
  description = "Show Cloud-init rendered file for SM"
  sensitive   = true
  value       = module.cloud-init-sm.cloudinit_config
}

output "cloud_init_am" {
  description = "Show Cloud-init rendered file for AM"
  sensitive   = true
  value       = module.cloud-init-am.cloudinit_config
}