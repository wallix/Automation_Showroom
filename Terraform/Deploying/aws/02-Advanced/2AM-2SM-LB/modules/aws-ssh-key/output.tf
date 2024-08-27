output "ssh_private_key" {
  description = "The SSH Private key in openssh format."
  value       = tls_private_key.key_pair.private_key_openssh
}

output "ssh_public_key" {
  description = "The SSH public key in openssh format."
  value       = tls_private_key.key_pair.public_key_openssh
}

output "key_pair_name" {
  description = "Name of the ssh Keypair which was created on AWS."
  value       = aws_key_pair.key_pair.key_name
}