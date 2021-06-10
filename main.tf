data "google_compute_image" "ubuntu" {
  family  = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

data "template_file" "nginx" {
  template = "${file("${path.module}/template/install_nginx.tpl")}"

  vars = {
    ufw_allow_nginx = "Nginx Full" # see https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance
  machine_type = var.machine_type
  tags         = ["allow-iap-ssh", "http-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  metadata_startup_script = data.template_file.nginx.rendered # https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file#rendered
}

resource "google_service_account" "vm_instance_sa" {
  project      = var.project
  account_id   = var.instance
  display_name = "Service Account for VM"
}

resource "google_compute_network" "vpc_network" {
  name                    = var.network
  auto_create_subnetworks = "true"
}

module "iap_tunneling" {
  source = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"

  project          = var.project
  network          = google_compute_network.vpc_network.self_link
  # service_accounts = [google_service_account.vm_instance_sa.email]
  network_tags     = ["allow-iap-ssh", "http-server", "https-server"]

  instances = [{
    name = google_compute_instance.vm_instance.name
    zone = var.zone
  }]

  members = [
    "user:jjgoi@google.com",
    "user:jiajian@bankon.cloud",
  ]
}