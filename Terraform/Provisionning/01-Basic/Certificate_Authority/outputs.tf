output "certificate_authorities" {
  description = "Certificate authorities created on the Bastion."
  value = [
    wallix-bastion_certificate_authority.ssh.certificate_authority_name,
    wallix-bastion_certificate_authority.x509.certificate_authority_name,
  ]
}
