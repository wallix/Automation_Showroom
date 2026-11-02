output "bastion_version" {
  description = "Version of the Bastion the example ran against."
  value       = data.wallix-bastion_version.current.wab_complete_version
}

output "user_name" {
  description = "Bastion user created by the example."
  value       = wallix-bastion_user.demo.user_name
}

output "user_password" {
  description = "Password of the Bastion user (terraform output -raw user_password)."
  value       = random_password.user.result
  sensitive   = true
}

output "user_private_key_file" {
  description = "Private SSH key of the Bastion user."
  value       = local_sensitive_file.user_private_key.filename
}

output "target" {
  description = "Target the user is authorized on."
  value       = "${wallix-bastion_domain_account.demo.account_name}@${wallix-bastion_domain.demo.domain_name}@${wallix-bastion_device.demo.device_name}:${wallix-bastion_device_service.ssh.service_name}"
}
