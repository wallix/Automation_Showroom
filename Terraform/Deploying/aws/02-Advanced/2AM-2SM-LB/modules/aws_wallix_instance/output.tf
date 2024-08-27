output "instance" {
  description = "Full information of the instance."
  value       = aws_instance.wallix
}

output "instance-id" {
  description = "ID of the instance."
  value       = aws_instance.wallix.id
}

output "instance_private_ip" {
  description = "Private IP of the instance."
  value       = aws_instance.wallix.private_ip
}

output "instance_network_interface_id" {
  description = "ID of the network interface linked to the instance."
  value       = aws_network_interface.wallix.id
}

output "ami-info" {
  description = "Info regarding the AMI used."
  value       = var.ami-override != "" ? "AMI Override was used !" : <<EOT
  "Image Name = ${data.aws_ami.wallix-ami.name}"
  "Image ID   = ${data.aws_ami.wallix-ami.id}"
  "Owner ID   = ${data.aws_ami.wallix-ami.owner_id}"
  EOT
}
