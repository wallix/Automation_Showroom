output "user_passwords" {
  description = "Bastion password of each user (terraform output -json user_passwords)."
  value       = { for k, u in wallix-bastion_user.users : u.user_name => random_password.users[k].result }
  sensitive   = true
}

output "account_public_keys" {
  description = "Public key generated for each account: add it to ~/.ssh/authorized_keys of the account on the SSH targets."
  value       = { for k, c in wallix-bastion_domain_account_credential.ssh_key : wallix-bastion_domain_account.users[k].account_name => trimspace(c.public_key) }
}

output "applications" {
  description = "Application created for each VM with a url."
  value       = { for k, app in wallix-bastion_application.apps : local.vms[k].name => app.application_name }
}
