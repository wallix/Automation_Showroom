output "ssh_private_key" {
  value = tls_private_key.key_pair.private_key_openssh
}

output "ssh_public_key" {
  value = tls_private_key.key_pair.public_key_openssh
}

output "key_pair_name" {
  value = aws_key_pair.key_pair.key_name
}