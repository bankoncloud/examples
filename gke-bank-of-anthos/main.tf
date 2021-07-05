# data "google_active_folder" "env" {
#   display_name = "${var.folder_prefix}-development"
#   parent       = var.parent_folder != "" ? "folders/${var.parent_folder}" : "organizations/${var.org_id}"
# }

data "google_projects" "environment_projects" {
  filter = "parent.id:${var.org_id} name:\"My First Project\" lifecycleState=ACTIVE"
}

data "google_project" "env_project" {
  project_id = data.google_projects.environment_projects.projects[0].project_id
}

resource "google_project_service" "project_activated_apis" {
  project = data.google_project.env_project.project_id
  service = "container.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

# Creates VPC network
resource "google_compute_network" "vpc_network" {
  project                 = data.google_project.env_project.project_id
  name                    = var.network
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "vpc_subnet_01" {
  project       = data.google_project.env_project.project_id
  name          = "asia-southeast1-01"
  ip_cidr_range = "10.148.0.0/20"
  region        = "asia-southeast1"
  network       = google_compute_network.vpc_network.self_link

  secondary_ip_range {
    range_name    = "asia-southeast1-01-gke-pods"
    ip_cidr_range = "192.168.0.0/20"
  }
  secondary_ip_range {
    range_name    = "asia-southeast1-01-gke-services"
    ip_cidr_range = "192.168.16.0/20"
  }
}

# GKE
# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

resource "google_service_account" "project_sa" {
  project      = data.google_project.env_project.project_id
  account_id   = "project-service-account"
  display_name = "Project Service Account for ${data.google_project.env_project.project_id}"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = data.google_project.env_project.project_id
  name                       = "bank-of-anthos-deployment"
  region                     = var.instance_region
  zones                      = ["${var.instance_region}-a"]
  network                    = google_compute_network.vpc_network.name
  subnetwork                 = google_compute_subnetwork.vpc_subnet_01.name
  ip_range_pods              = "${var.instance_region}-01-gke-pods"
  ip_range_services          = "${var.instance_region}-01-gke-services"
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  network_policy             = false


  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "e2-small"
      node_locations     = "${var.instance_region}-a,${var.instance_region}-b"
      min_count          = 1
      max_count          = 8
      local_ssd_count    = 0
      disk_size_gb       = 10
      disk_type          = "pd-balanced"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = google_service_account.project_sa.email
      preemptible        = false
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }

  depends_on = [
    google_project_service.project_activated_apis
  ]
}
