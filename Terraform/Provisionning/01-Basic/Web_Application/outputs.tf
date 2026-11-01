output "application" {
  description = "Web application created on the Bastion."
  value       = wallix-bastion_application.webapp.application_name
}

output "target" {
  description = "Target the user group is authorized on (account@domain@application)."
  value       = "${wallix-bastion_domain_account.webapp.account_name}@${wallix-bastion_domain.webapp.domain_name}@${wallix-bastion_application.webapp.application_name}"
}
