output "connection_policy" {
  description = "Connection policy created from the built-in SSH policy."
  value       = wallix-bastion_connection_policy.ssh_timeout.connection_policy_name
}

output "service" {
  description = "Service that uses the policy (device:service)."
  value       = "${wallix-bastion_device.server.device_name}:${wallix-bastion_device_service.ssh.service_name}"
}
