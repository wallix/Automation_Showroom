output "wallix_password_wabadmin" {
  value     = random_password.password["wabadmin"].result
  sensitive = true
}

output "wallix_password_wabsuper" {
  value     = random_password.password["wabsuper"].result
  sensitive = true
}

output "wallix_password_wabupgrade" {
  value     = random_password.password
  sensitive = true
}

output "cloudinit_config" {
  value     = data.cloudinit_config.wallix_appliance.rendered
  sensitive = true
}