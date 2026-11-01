output "existing_group_members" {
  description = "Members of the existing user group, read by the data source: they can now open the server."
  value       = data.wallix-bastion_usergroup.existing.users
}

output "device_tags" {
  description = "Tags of the new device."
  value       = { for tag in wallix-bastion_device.web.tags : tag.key => tag.value }
}
