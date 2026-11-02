output "mappings" {
  description = "Bastion user group => Entra ID group object ID."
  value       = { for k, m in wallix-bastion_authdomain_mapping.entra : m.user_group => m.external_group }
}
