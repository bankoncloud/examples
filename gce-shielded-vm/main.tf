resource "google_project_service" "project_activated_apis" {
  project = var.project
  service = "container.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

data "template_file" "nginx" {
  template = file("${path.module}/templates/install_nginx.tpl")

  vars = {
    ufw_allow_nginx = "Nginx Full" # see https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04
  }
}

# Creates VPC network
resource "google_compute_network" "vpc_network" {
  project                 = var.project
  name                    = var.network
  auto_create_subnetworks = "false"
}

# Creates subnets
resource "google_compute_subnetwork" "vpc_subnet_01" {
  project       = var.project
  name          = "asia-southeast1-01"
  ip_cidr_range = "10.148.0.0/20"
  region        = "asia-southeast1"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "${google_compute_network.vpc_network.name}-allow-icmp"
  network = google_compute_network.vpc_network.self_link
  project = var.project

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${google_compute_network.vpc_network.name}-allow-http"
  network = google_compute_network.vpc_network.self_link
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "${google_compute_network.vpc_network.name}-allow-https"
  network = google_compute_network.vpc_network.self_link
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Creates the actual VM workload

resource "google_compute_instance" "vm_instance" {
  project      = var.project
  zone         = var.zone
  name         = var.instance_name
  machine_type = var.machine_type
  tags         = ["allow-iap-ssh", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    # We use the designated subnet 01 to place VM workloads
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.vpc_subnet_01.self_link

    access_config {
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true

  metadata_startup_script = data.template_file.nginx.rendered # https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file#rendered

  depends_on = [
    module.org_vm_external_ip_access
  ]
}

resource "google_service_account" "vm_instance_sa" {
  project      = var.project
  account_id   = var.instance_name
  display_name = "Service Account for VM"
}

module "iap_tunneling" {
  source = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"

  project = var.project
  network = google_compute_network.vpc_network.self_link
  # service_accounts = [google_service_account.vm_instance_sa.email]
  network_tags = ["allow-iap-ssh"]

  instances = [{
    name = google_compute_instance.vm_instance.name
    zone = var.zone
  }]

  members = []
}