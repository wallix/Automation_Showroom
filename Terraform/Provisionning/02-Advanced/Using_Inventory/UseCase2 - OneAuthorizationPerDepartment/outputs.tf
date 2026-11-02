output "user_passwords" {
  description = "Bastion password of each user (terraform output -json user_passwords)."
  value       = { for k, u in wallix-bastion_user.users : u.user_name => random_password.users[k].result }
  sensitive   = true
}

output "account_public_keys" {
  description = "Public key generated for each SSH account: add it to ~/.ssh/authorized_keys of the account on the server."
  value = {
    for k, c in wallix-bastion_device_localdomain_account_credential.ssh_key :
    "${wallix-bastion_device_localdomain_account.vms[k].account_name}@${wallix-bastion_device.vms[k].device_name}" => trimspace(c.public_key)
  }
}
