output "cluster" {
  description = "Cluster of jump servers."
  value       = wallix-bastion_cluster.rds.cluster_name
}

output "cluster_members" {
  description = "Targets of the cluster (account@domain@device:service)."
  value       = wallix-bastion_cluster.rds.accounts
}

output "application" {
  description = "Standard application whose target is the cluster."
  value       = wallix-bastion_application.app.application_name
}
