
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}

variable "min_nodes" {
  default = "1"
}
variable "max_nodes" {
  default = "1"
}
variable "project_name" {}
variable "linux_admin_username" {}
variable "linux_admin_password" {}

provider "google" {
  credentials = "${file("~/.gcloud/OneHQ.json")}"
  project     = "${var.project_name}"
  region      = "${var.region}"
  zone        = "${var.zone}$"
}

resource "google_container_cluster" "primary" {
  name = "first-cluster"
  zone = "${var.zone}"
  initial_node_count = 1

  # enable autoscaling
  provisioner "local-exec" {
      command = "gcloud container clusters update ${google_container_cluster.primary.name} --zone ${var.zone} --enable-autoscaling --min-nodes=${var.min_nodes} --max-nodes=${var.max_nodes} --project='${var.project_name}'"
  }

  master_auth {
      username = "${var.linux_admin_username}"
      password = "${var.linux_admin_password}}"
  }

  node_config {
    machine_type = "n1-standard-1"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

resource "google_compute_global_address" "hello-ip" {
  name = "first-cluster-hello-web-ip"
  ip_version = "IPV4"
}

resource "google_dns_managed_zone" "twajr" {
  name        = "twajr-net-zone"
  dns_name    = "twajr.net."
  description = "twajr.net DNS zone"
}
resource "google_dns_record_set" "hello-endpoint-twajr" {
  name  = "hello.${google_dns_managed_zone.twajr.dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = "${google_dns_managed_zone.twajr.name}"

  rrdatas = ["${google_compute_global_address.hello-ip.address}"]
}

output "cluster_name" {
  value = "${google_container_cluster.primary.name}"
}

output "primary_zone" {
  value = "${google_container_cluster.primary.zone}"
}

output "additional_zones" {
  value = "${google_container_cluster.primary.additional_zones}"
}

output "endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "node_version" {
  value = "${google_container_cluster.primary.node_version}"
}
