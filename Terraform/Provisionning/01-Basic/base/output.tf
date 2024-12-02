output "version_info" {
  value       = data.wallix-bastion_version.version
  description = "Session Manager version info"
}

output "username" {
  value       = random_pet.user.id
  description = "Generated Username"
}

output "password" {
  value       = random_string.demo.result
  description = "Randomly generated password for the user"
}

output "group" {
  value       = random_pet.group.id
  description = "Generated Group Name"
}