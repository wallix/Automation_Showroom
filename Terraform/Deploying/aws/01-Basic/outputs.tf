output "aws_instance_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.product_instance.public_ip
}

output "aws_instance_id" {
  description = "ID of the instance."
  value       = aws_instance.product_instance.id
}

output "aws_ami_name" {
  description = "Name of the AMI used."
  value       = data.aws_ami.ami.name
}
