output "vm_instance_private_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}
