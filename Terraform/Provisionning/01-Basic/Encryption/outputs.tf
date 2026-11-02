output "seal_state" {
  description = "need_setup, sealed (passphrase to enter, e.g. after a reboot) or unsealed."
  value       = data.wallix-bastion_encryption.current.seal_state
}

output "encryption_mode" {
  description = "need_setup, unprotected (no passphrase) or passphrase."
  value       = data.wallix-bastion_encryption.current.encryption_mode
}
