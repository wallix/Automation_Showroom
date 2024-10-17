output "wallix_password_wabadmin" {
  description = "Wabadmin password"
  value       = random_password.password["wabadmin"].result
  sensitive   = true
}

output "wallix_password_wabsuper" {
  description = "Wabsuper password"
  value       = random_password.password["wabsuper"].result
  sensitive   = true
}

output "wallix_password_wabupgrade" {
  description = "Wabupgrade password"
  value       = random_password.password["wabupgrade"].result
  sensitive   = true
}

output "wallix_password_webui" {
  description = "Webui Admin password"
  value       = random_password.webui_password.result
  sensitive   = true
}

output "wallix_crypto" {
  description = "Cryptokey"
  value       = random_password.cryptokey_password.result
  sensitive   = true
}

output "cloudinit_config" {
  description = "The rendered user-data / cloud-init data"
  value       = data.cloudinit_config.wallix_appliance.rendered
  sensitive   = true
}