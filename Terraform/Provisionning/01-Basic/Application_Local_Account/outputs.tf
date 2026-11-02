output "application" {
  description = "Web application created on the Bastion."
  value       = wallix-bastion_application.webapp.application_name
}

output "target" {
  description = "Target of the target group (account@local domain@application)."
  value       = "${wallix-bastion_application_localdomain_account.admin.account_name}@${wallix-bastion_application_localdomain.local.domain_name}@${wallix-bastion_application.webapp.application_name}"
}
