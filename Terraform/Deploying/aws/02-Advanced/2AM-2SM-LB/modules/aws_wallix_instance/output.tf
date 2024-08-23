output "instance" {
  value = aws_instance.wallix
}

output "instance-id" {
  value = aws_instance.wallix.id
}

output "instance_private_ip" {
  value = aws_instance.wallix.private_ip
}

output "instance_network_interface_id" {
  value = aws_network_interface.wallix.id
}