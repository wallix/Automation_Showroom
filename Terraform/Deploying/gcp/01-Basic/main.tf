

provider "google" {
  region      = var.gcp_region
  project     = var.gcp_project_name
  credentials = file(var.gcp_credentials_file_path)
  zone        = var.gcp_region_zone
}

provider "cloudinit" {
}


locals {
  source_uri                = "https://storage.googleapis.com/${var.gcp_bucket_name}/${var.product_name}-${var.product_version}-gcp.tar.gz"
  sanitized_product_version = replace(var.product_version, ".", "-")
  disk_name                 = "disk-${var.product_name}-${local.sanitized_product_version}"
  image_name                = "image-${var.product_name}-${local.sanitized_product_version}"
  instance_name             = "instance-${var.product_name}-${local.sanitized_product_version}"
  network                   = "network-${var.product_name}-${local.sanitized_product_version}"
}


resource "google_compute_image" "product_image" {
  name = local.image_name

  raw_disk {
    source = local.source_uri
  }
  labels = {
    environment = "testingwallix"
  }
}

resource "google_compute_disk" "product_disk" {
  name  = local.disk_name
  zone  = var.gcp_region_zone
  type  = "pd-standard"
  image = google_compute_image.product_image.name
  labels = {
    environment = "testingwallix"
  }
  size                      = 30
  physical_block_size_bytes = 4096
}


resource "google_compute_network" "product_network" {
  name                    = local.network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "product_subnetwork" {
  name          = "${local.network}-subnetwork-${var.gcp_region}"
  region        = var.gcp_region
  network       = google_compute_network.product_network.self_link
  ip_cidr_range = var.cidr_range
}



resource "google_compute_firewall" "accessmanager" {
  name    = "firewall-${local.network}"
  network = google_compute_network.product_network.name
  count   = var.product_name == "access-manager" ? 1 : 0

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2242", "22"]
  }

  target_tags   = ["firewall-${local.network}"]
  source_ranges = var.allowed_ip
}

resource "google_compute_firewall" "bastion" {
  name    = "firewall-${local.network}"
  network = google_compute_network.product_network.name
  count   = var.product_name == "bastion" ? 1 : 0

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2242", "22", "3389"]
  }

  target_tags   = ["firewall-${local.network}"]
  source_ranges = var.allowed_ip

}

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    wabadmin_password   = var.wabadmin_password
    wabsuper_password   = var.wabsuper_password
    wabupgrade_password = var.wabupgrade_password
  }

}

data "cloudinit_config" "conf" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloudinit.rendered
    filename     = "cloud-init.yaml"
  }
}
resource "google_compute_instance" "product_instance" {
  name         = local.instance_name
  machine_type = var.gcp_instance_size
  zone         = var.gcp_region_zone

  tags = [
    "firewall-${local.network}",
  ]

  metadata = {
    user-data = "${data.cloudinit_config.conf.rendered}"
    ssh-keys  = "root:${var.ssh_key_root}\nwabadmin:${var.ssh_key_wabadmin}"
  }
  boot_disk {
    source = google_compute_disk.product_disk.name
  }

  network_interface {
    subnetwork = google_compute_subnetwork.product_subnetwork.name
    access_config {
      // Ephemeral public IP
    }
  }

  #   service_account {
  #     email  = "testwab-143414@email.com"
  #     scopes = [
  #         "storage-ro",
  #         "logging-write",
  #         "monitoring-write",
  #         "service-control",
  #         "service-management",
  #         "trace"
  #     ]
  #   }
}
