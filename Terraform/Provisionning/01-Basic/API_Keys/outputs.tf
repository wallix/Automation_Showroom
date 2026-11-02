output "apikey_name" {
  description = "Name of the API key, as listed in the Bastion."
  value       = wallix-bastion_apikey_v2.reporting.apikey_name
}

output "apikey_rights" {
  description = "Rights the profile gives to the key (view or modify, per feature)."
  value       = { for feature, right in data.wallix-bastion_profile.key.gui_features[0] : feature => right if right != "" }
}
