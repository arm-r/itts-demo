//----------------------------------- VM Instance Vars -----------------------------------//

variable "google_project" {
  default     = "project-arz"
}

variable "google_region" {
  default     = "asia-southeast2"
}

variable "network_name" {
  default     = "workshop"
}

variable "subnetwork_name" {
  default     = "subnet-01"
}

variable "server_machine_type" {
  default     = "n2-standard-2"
}

variable "server_startup_script_master" {  
  default     = <<EOF
  apt update
  apt install apache2 -y
  echo "Hello World - Workshop ITTS" > /var/www/html/index.html  
  EOF
}

variable "service_server_scopes" {
  default     = "cloud-platform"
}

variable "server_ip" {
  default     = "server-ip"
}

variable "server_name" {
  default     = "server-01"
}

variable "zone" {
  default     = "asia-southeast2-b"
}

//----------------------------------- VM Configuration -----------------------------------//

terraform {
  backend "gcs" {
    bucket  = "workshop-terraform-state"
    prefix  = "global/server"
  }
}

provider "google" {
  alias       = "google-vminstance"
  project     = var.google_project
  region      = var.google_region
}

resource "google_compute_address" "server_ip" {
  name         = var.server_ip
  subnetwork   = var.subnetwork_name
  address_type = "INTERNAL"
  address      = "10.1.1.17"
  region       = var.google_region
}

resource "google_compute_address" "server_ext_ip" {
  name    = "server-ext-ip"
  region  = var.google_region
}

resource "google_compute_instance" "server" {
  name            = var.server_name
  machine_type    = var.server_machine_type
  zone            = var.zone
  can_ip_forward  = true
  tags            = ["server-firewall"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network       = var.network_name
    access_config {
      nat_ip = google_compute_address.server_ext_ip.address
    }
    subnetwork    = var.subnetwork_name
    network_ip    = google_compute_address.server_ip.self_link
  }
  metadata_startup_script = var.server_startup_script_master
  service_account {
    scopes = [var.service_server_scopes]
  }
}

//----------------------------------- END -----------------------------------//
