output "password_change_policy" {
  description = "Password change policy used by the domain."
  value       = wallix-bastion_passwordchangepolicy.weekly.password_change_policy_name
}

output "account" {
  description = "Account whose password the Bastion rotates (account@domain)."
  value       = "${wallix-bastion_domain_account.svc.account_name}@${wallix-bastion_domain.ad.domain_name}"
}

output "domain_password_change" {
  description = "true when the domain of the account has a password change configured, the condition for the rotation."
  value       = wallix-bastion_domain_account.svc.domain_password_change
}
