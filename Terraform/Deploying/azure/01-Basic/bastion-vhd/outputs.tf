output "private_ip" {
  description = "Private IP of the VM."
  value       = azurerm_network_interface.nic.private_ip_address
}

output "public_ip" {
  description = "Public IP of the VM, null when allowed_ips is empty."
  value       = try(azurerm_public_ip.public_ip[0].ip_address, null)
}

output "vm_id" {
  description = "ID of the VM."
  value       = azurerm_linux_virtual_machine.vm-bastion.id
}
