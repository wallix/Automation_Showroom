output "gcp_instance_ip" {
  description = "Public IP of the instance."
  value       = google_compute_instance.product_instance.network_interface[0].access_config[0].nat_ip
}

output "gcp_instance_private_ip" {
  description = "Private IP of the instance."
  value       = google_compute_instance.product_instance.network_interface[0].network_ip
}
