output "vm_instance_private_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "vm_instance_public_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
