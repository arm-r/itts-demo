//------------------------- Network Vars -------------------------//

variable "google_project" {
  default     = "project-arz"
}

variable "cloud_region" {
  default     = "asia-southeast2"
}

variable "network_name" { 
  default     = "workshop"
}

variable "subnet_01_name" {
  default     = "subnet-01"
}

variable "subnet_02_name" {
  default     = "subnet-02"
}

variable "subnet_01_ip" {
  default     = "10.1.1.0/24"
}

variable "subnet_02_ip" {
  default     = "10.1.2.0/24"
}

variable "cloud_nat_name" {
  default     = "workshop-cloud-nat"
}

variable "cloud_router_name" {
  default     = "workshop-router"
}

//------------------------- Network Configuration -------------------------//

terraform {
  backend "gcs" {
    bucket  = "workshop-terraform-state"
    prefix  = "global/network"
  }
}

provider "google" {
  alias       = "google-net"
  region      = var.cloud_region
  project     = var.google_project
}

resource "google_compute_subnetwork" "subnet-01" {
  name          = var.subnet_01_name
  ip_cidr_range = var.subnet_01_ip
  region        = var.cloud_region
  network       = google_compute_network.vpc-name.id
}

resource "google_compute_subnetwork" "subnet-02" {
  name          = var.subnet_02_name
  ip_cidr_range = var.subnet_02_ip
  region        = var.cloud_region
  network       = google_compute_network.vpc-name.id
}

resource "google_compute_network" "vpc-name" {
  name                    = var.network_name
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

//------------------------- Basic Firewall Configuration -------------------------//

resource "google_compute_firewall" "server_fw" {
  name    = "server-firewall"
  network = google_compute_network.vpc-name.name
  allow {
    protocol = "tcp"
    ports    = ["22","80","8080","443","8443"]
  }
  target_tags   = ["server-firewall"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "sql_fw" {
  name    = "sql-firewall"
  network = google_compute_network.vpc-name.name
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  target_tags   = ["sql-firewall"]
  source_ranges = ["35.191.0.0/16","103.245.0.0/16"]
}

//------------------------- Cloud NAT Configuration -------------------------//

resource "google_compute_address" "nat_global_ip" {
  count   = 2
  name    = "workshop-nat-global-ip-address-${count.index}"
  region  = var.cloud_region
}

resource "google_compute_router" "router" {
  name    = var.cloud_router_name
  region  = var.cloud_region
  network = google_compute_network.vpc-name.name
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = var.cloud_nat_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat_global_ip.*.self_link
  min_ports_per_vm                   = 4000
  tcp_established_idle_timeout_sec   = 2000000
  tcp_transitory_idle_timeout_sec    = 2000000
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

//------------------------------------- END -------------------------------------//
