output "ca_public_key" {
  description = "Public key of the CA of the domain, to add to TrustedUserCAKeys on the SSH servers."
  value       = wallix-bastion_domain.ssh_ca.ca_public_key
}

output "account_certificate" {
  description = "SSH certificate of the account, signed by the CA of the domain (public_key of the credential)."
  value       = wallix-bastion_domain_account_credential.admin.public_key
}

output "target" {
  description = "Target that logs in with a certificate (account@domain@device:service)."
  value       = "${wallix-bastion_domain_account.admin.account_name}@${wallix-bastion_domain.ssh_ca.domain_name}@${wallix-bastion_device.server.device_name}:${wallix-bastion_device_service.ssh.service_name}"
}
